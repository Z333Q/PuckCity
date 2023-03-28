// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PuckCity is ERC1155Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Constants
    uint256 public constant NUM_TEAMS = 32;
    uint256 public constant NUM_TOKENS_PER_TEAM = 1000;
    uint256 public constant TOTAL_TOKENS = NUM_TEAMS * NUM_TOKENS_PER_TEAM;
    uint256 public constant TOKEN_PRICE = 1 ether;
    uint256 public constant TRANSACTION_FEE_PERCENTAGE = 50; // 0.5%
    uint256 public constant SECONDS_PER_DAY = 86400;

    // Structs
    struct Team {
        uint256 wins;
        uint256 losses;
        uint256 treasury;
        mapping(address => uint256) balances;
    }

    // Variables
    address public owner;
    AggregatorV3Interface internal priceFeed;
    IERC1155 public teamTokens;
    IERC20 public paymentToken;
    mapping(uint256 => Team) public teams;
    mapping(address => uint256) public balances;
    uint256 public totalSupply;
    uint256 public startTime;
    bool public gameEnded;

    // Events
    event TokensPurchased(address indexed buyer, uint256 amount);
    event TokensRedeemed(address indexed seller, uint256 amount);
    event FundsRedistributed(uint256 indexed teamIndex, uint256 winTreasury, uint256 lossTreasury);
    event GameEnded();
    event StakesPurchased(address indexed buyer, uint256 indexed teamIndex, uint256 amount);
    event StakesRedeemed(address indexed seller, uint256 indexed teamIndex, uint256 amount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier gameNotEnded() {
        require(!gameEnded, "Game has ended");
        _;
    }

    // Constructor
    constructor(
        address _priceFeedAddress,
        address _teamTokensAddress,
        address _paymentTokenAddress
    ) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        teamTokens = IERC1155(_teamTokensAddress);
        paymentToken = IERC20(_paymentTokenAddress);
        startTime = block.timestamp;
        totalSupply = TOTAL_TOKENS;
    }

    // Public functions
    function purchaseTokens(uint256 _amount) public payable gameNotEnded {
        require(_amount > 0, "Amount must be greater than 0");
        require(totalSupply >= _amount, "Not enough tokens available");
        require(msg.value == _amount * TOKEN_PRICE, "Incorrect amount of ETH sent");

        // Distribute tokens to buyer
        balances[msg.sender] += _amount;
        totalSupply -= _amount;

        // Distribute funds to team treasury
        uint256 teamIndex = (msg.value * NUM_TEAMS) / (TOTAL_TOKENS * TOKEN_PRICE);
        teams[teamIndex].treasury += msg.value - (msg.value * TRANSACTION FEE_PERCENTAGE) / 10000;
            // Emit event
    emit TokensPurchased(msg.sender, _amount, teamIndex);
}

function redeemTokens(uint256 _amount) public gameNotEnded {
    require(_amount > 0, "Amount must be greater than 0");
    require(balances[msg.sender] >= _amount, "Insufficient balance");

    // Remove tokens from buyer
    balances[msg.sender] -= _amount;
    totalSupply += _amount;

    // Distribute funds from team treasury
    uint256 teamIndex = (_amount * NUM_TEAMS) / NUM_TOKENS_PER_TEAM;
    uint256 amountToRedeem = (teams[teamIndex].treasury * _amount) / NUM_TOKENS_PER_TEAM;
    teams[teamIndex].treasury -= amountToRedeem;
    payable(msg.sender).transfer(amountToRedeem);

    // Emit event
    emit TokensRedeemed(msg.sender, _amount, teamIndex);
}

function getTeamBalance(uint256 _teamIndex) public view returns (uint256) {
    return teams[_teamIndex].treasury;
}

function getTeamWins(uint256 _teamIndex) public view returns (uint256) {
    return teams[_teamIndex].wins;
}

function getTeamLosses(uint256 _teamIndex) public view returns (uint256) {
    return teams[_teamIndex].losses;
}

function endGame() public onlyOwner {
    require(block.timestamp >= startTime + (82 * SECONDS_PER_DAY), "Regular season not over");

    // Set gameEnded to true
    gameEnded = true;

    // Distribute remaining funds to team treasuries
    _redistributeFunds();

    // Emit event
    emit GameEnded();
}

// Internal functions
function _updateTeamWinsLosses() internal {
    for (uint256 i = 0; i < NUM_TEAMS; i++) {
        int256 homeScore;
        int256 awayScore;

        (, homeScore, , , ) = priceFeed.latestRoundData(i * 2);
        (, awayScore, , , ) = priceFeed.latestRoundData(i * 2 + 1);

        uint256 homeTeamIndex = (uint256(homeScore) * NUM_TEAMS) / 100;
        uint256 awayTeamIndex = (uint256(awayScore) * NUM_TEAMS) / 100;

        if (homeTeamIndex == i) {
            teams[i].wins++;
        } else if (awayTeamIndex == i) {
            teams[i].losses++;
        }
    }
}

function _redistributeFunds() internal {
    for (uint256 i = 0; i < NUM_TEAMS; i++) {
        uint256 teamTreasury = teams[i].treasury;

        if (teamTreasury > 0) {
            uint256 totalWinsLosses = teams[i].wins + teams[i].losses;
            uint256 winPercentage = (teams[i].wins * 10000) / totalWinsLosses;
            uint256 winTreasury = (teamTreasury * winPercentage) / 10000;
            uint256 lossTreasury = teamTreasury - winTreasury;

            teams[i].treasury = 0;
            teams[i].balances[address(this)] += winTreasury;
            teams[i].balances[address(this)] += lossTreasury;

            // Emit event
            emit FundsRedistributed(i, winTreasury, lossTreasury);
        }
    }
}
}
   
   
