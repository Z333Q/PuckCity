// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "https://github.com/maticnetwork/pos-portal/contracts/root/RootChainManager.sol";

contract PuckCity is ERC20, ERC1155, Ownable, Pausable, ChainlinkClient {
    uint256 private constant TEAM_COUNT = 32;
    uint256 private constant TOKENS_PER_TEAM = 1000;
    uint256 private constant PERCENT_MULTIPLIER = 1000; // For 0.5% transaction fee
    uint256 private constant MAX_SCORE = 100;
    uint256 private constant BASE = 10**8;
    uint256 private constant ETHER_IN_WEI = 1 ether;

    uint256 public transactionFee = 5; // 0.5%
    uint256 public globalTreasury;
    uint256 private oraclePaymentAmount;

    mapping(uint256 => uint256) public reserves;
    mapping(uint256 => address) public teamTreasury;
    mapping(uint256 => mapping(uint256 => GameResult)) public gameResults;
    mapping(bytes32 => uint256) private requestIdToTeamId;
    mapping(bytes32 => uint256) private requestIdToRound;
    uint256 public lastResultUpdateBlock;

    AggregatorV3Interface private priceFeed;
    IERC20 private immutableX;
    RootChainManager private rootChainManager;
    address private oracle;

 struct GameResult {
    uint256 homeScore;
    uint256 awayScore;
    bool resultSubmitted;
    uint256 score;
}

    bytes32 private jobId;

    modifier onlyOracle() {
        require(msg.sender == oracle, "Only oracle can call this function.");
        _;
    }

    constructor(
        address[] memory _teamTreasuryAddresses,
        string memory _uri,
        address _priceFeedAddress,
        address _immutableXAddress,
        address _rootChainManagerAddress,
        bytes32 _jobId,
        address _oracleAddress,
        uint256 _oraclePaymentAmount
    ) ERC20("Puck City", "PUCK") ERC1155(_uri) {
        require(_teamTreasuryAddresses.length == TEAM_COUNT, "Invalid team treasury addresses length");
        for (uint256 i = 0; i < TEAM_COUNT; i++) {
            teamTreasury[i] = _teamTreasuryAddresses[i];
        }
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        immutableX = IERC20(_immutableXAddress);
        rootChainManager = RootChainManager(_rootChainManagerAddress);
        jobId = _jobId;
        oraclePaymentAmount = _oraclePaymentAmount;
        oracle = _oracleAddress;
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 totalSupply = totalSupply();
        uint256 reserveBalance = getReserveBalance(totalSupply);
        return _calculatePrice(totalSupply + 1, reserveBalance);
    }

    function _calculatePrice(uint256 _supply, uint256 _reserveBalance) internal pure returns (uint256) {
        return (_reserveBalance * 1000000) / (_supply**2 - _supply + 1);
    }

    function purchaseToken(uint256 _amount, uint256 _teamId) public payable whenNotPaused {
        require(_amount > 0 && _amount <= TOKENS_PER_TEAM, "Invalid amount");
        require(_teamId < TEAM_COUNT, "Invalid team ID");
        uint256 totalSupply = totalSupply();
        require(totalSupply < TEAM_COUNT * TOKENS_PER_TEAM, "All tokens have been minted");
        uint256 currentPrice = getCurrentPrice();
        uint256 totalPrice = currentPrice * _amount;
        require(msg.value >= totalPrice, "Insufficient payment");

        reserves[_teamId * TOKENS_PER_TEAM + (totalSupply % TOKENS_PER_TEAM)] += totalPrice;

        _mint(msg.sender, totalSupply + 1, _amount, "");

        // Transfer 0.5% of the payment to the contract owner
        uint256 transactionFeeAmount = (totalPrice * transactionFee) / PERCENT_MULTIPLIER;
        (bool transferToOwner,) = payable(owner()).call{value: transactionFeeAmount}();
        require(transferToOwner, "Transfer to contract owner failed");

        // Transfer remaining payment to global treasury
        uint256 remainingAmount = totalPrice - transactionFeeAmount;
        globalTreasury += remainingAmount;
    }

    function claimToken(uint256 _teamId) public {
        uint256 totalSupply = totalSupply();
        require(totalSupply == TEAM_COUNT * TOKENS_PER_TEAM, "Tokens not fully minted yet");
        require(_teamId < TEAM_COUNT, "Invalid team ID");
        uint256 balance = balanceOf(msg.sender, _teamId + 1);
        require(balance > 0, "Balance is zero");
        uint256 reserveBalance = reserves[_teamId * TOKENS_PER_TEAM + balance - 1];
        uint256 currentPrice = getCurrentPrice();
        uint256 value = (reserveBalance * balance * currentPrice) / (TOKENS_PER_TEAM * ETHER_IN_WEI);
        reserves[_teamId * TOKENS_PER_TEAM + balance - 1] = 0;
        _burn(msg.sender, _teamId + 1, balance);

        bool transferFromSuccess = immutableX.transferFrom(msg.sender, address(this), value);
        require(transferFromSuccess, "Transfer from user failed");

        globalTreasury += value;
    }

    function getReserveBalance(uint256 _totalSupply) public view returns (uint256) {
        uint256 balance = address(this).balance - globalTreasury;
        return balance + ((priceFeed.latestAnswer() * _totalSupply * ETHER_IN_WEI) / BASE);
    }

    function updateResults(uint256 _teamId, uint256 _round) public returns (bytes32) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        request.add("get", "https://api.sportsdata.io/v3/nhl/scores/json/TeamGameStats");
        string[] memory path = new string[](5);
        path[0] = "TeamGameStats";
        path[1] = _toString(_teamId);
        path[2] = "Round";
        path[3] = _toString(_round);
        path[4] = "Score";
        request.addStringArray("path", path);
        bytes32 requestId = sendChainlinkRequestTo(oracle, request, oraclePaymentAmount);

        requestIdToTeamId[requestId] = _teamId;
        requestIdToRound[requestId] = _round;

        return requestId;
    }

    function fulfill(bytes32 _requestId, uint256 _score) public recordChainlinkFulfillment(_requestId) {
        uint256 _teamId = requestIdToTeamId[_requestId];
        uint256 _round = requestIdToRound[_requestId];
        delete requestIdToTeamId[_requestId];
        delete requestIdToRound[_requestId];
        
        // Store the result
        GameResult memory result = GameResult(_score, true);
        gameResults[_teamId][_round] = result;
        lastResultUpdateBlock = block.number;

        // Then redistribute funds based on result
        redistributeFunds(_teamId, _round);
    }

    function updateResult(uint256 _teamId, uint256 _round, uint256 _homeScore, uint256 _awayScore) public onlyOracle {
        require(_teamId < TEAM_COUNT, "Invalid team ID");
        require(_round > 0, "Invalid round number");
        require(_homeScore <= MAX_SCORE, "Invalid home score");
        require(_awayScore <= MAX_SCORE, "Invalid away score");
        gameResults[_teamId][_round] = GameResult(_homeScore, _awayScore, true);
        lastResultUpdateBlock = block.number;

        redistributeFunds(_teamId, _round);
    }

    function redistributeFunds(uint256 _teamId, uint256 _round) internal {
        uint256 winningReserve = 0;
        uint256 losingReserve = 0;

        for (uint256 i = 0; i < TEAM_COUNT; i++) {
            if (i == _teamId) {
                continue;
            }
            GameResult memory result = gameResults[i][_round];
            if (!result.resultSubmitted) {
                continue;
            }
            uint256 reserve = reserves[i * TOKENS_PER_TEAM + TOKENS_PER_TEAM - 1];
            if (result.homeScore > result.awayScore) {
                winningReserve += reserve;
            } else {
                losingReserve += reserve;
            }
        }
        GameResult memory _result = gameResults[_teamId][_round];
        if (_result.resultSubmitted) {
            uint256 reserve = reserves[_teamId * TOKENS_PER_TEAM + TOKENS_PER_TEAM - 1];
            if (_result.homeScore > _result.awayScore) {
                winningReserve += reserve;
            } else {
                losingReserve += reserve;
            }
        }
        uint256 totalReserve = winningReserve + losingReserve;
        if (totalReserve == 0) {
            return;
        }
        uint256 winningPercentage = (winningReserve * PERCENT_MULTIPLIER) / totalReserve;
        uint256 losingPercentage = (losingReserve * PERCENT_MULTIPLIER) / totalReserve;
        uint256 winningAmount = (globalTreasury * winningPercentage) / PERCENT_MULTIPLIER;
        uint256 losingAmount = (globalTreasury * losingPercentage) / PERCENT_MULTIPLIER;

        (bool transferToWinner,) = teamTreasury[_teamId].call{value: winningAmount}("");
        require(transferToWinner, "Transfer to winning team treasury failed");

        (bool transferToLoser,) = teamTreasury[TEAM_COUNT - _teamId - 1].call{value: losingAmount}("");
        require(transferToLoser, "Transfer to losing team treasury failed");

        globalTreasury -= winningAmount + losingAmount;
    }

    function setTransactionFee(uint256 _transactionFee) public onlyOwner {
        require(_transactionFee < PERCENT_MULTIPLIER, "Invalid transaction fee");
        transactionFee = _transactionFee;
    }

    function withdrawFromTeamTreasury(uint256 _teamId, uint256 _amount) public onlyOwner {
        require(_teamId < TEAM_COUNT, "Invalid team ID");
        require(_amount <= immutableX.balanceOf(teamTreasury[_teamId]), "Insufficient balance in team treasury");
        (bool success,) = owner().call{value: _amount}("");
        require(success, "Withdrawal from team treasury failed");
    }

    function setURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function migrateERC20ToPolygon(uint256 _amount) public onlyOwner {
        (bool success,) = address(rootChainManager).call{value: _amount}("");
        require(success, "Transfer to Polygon failed");
        rootChainManager.depositERC20(address(immutableX), msg.sender, _amount);
    }

    function migrateERC1155ToPolygon(uint256[] memory _ids, uint256[] memory _amounts) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            _mint(address(this), _ids[i], _amounts[i], "");
            rootChainManager.depositERC1155(address(this), _ids, _amounts);
            _burn(address(this), _ids[i], _amounts[i]);
        }
    }

    function withdrawFromGlobalTreasury(uint256 _amount) public onlyOwner {
        require(_amount <= immutableX.balanceOf(address(this)), "Insufficient balance in global treasury");
        (bool success,) = owner().call{value: _amount}("");
        require(success, "Withdrawal from global treasury failed");
    }

// This is a utility function to convert uint to string.
    function _toString(uint256 value) internal pure returns(string memory) {
      // Convert a uint value to its decimal string representation.
      if (value == 0) {
        return "0";
      }
      uint256 temp = value;
      uint256 digits;
      while (temp != 0) {
        digits++;
        temp /= 10;
      }
      bytes memory buffer = new bytes(digits);
      while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
      }
      return string(buffer);
    }
}
