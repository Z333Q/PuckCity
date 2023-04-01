// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/PolygonCompatibleERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PuckCityV7 is PolygonCompatibleERC1155, VRFConsumerBase, Ownable {
    using SafeMath for uint256;

    IERC20Metadata private _token;
    address private _treasury;
    AggregatorV3Interface public scoreFeed;

    uint256 private constant TOTAL_SUPPLY = 32000 * 10 ** 18;
    uint256 private constant SCORE_DECIMALS = 10000;

    mapping(string => Team) public teams;
    mapping(address => mapping(string => uint256)) public stakedBalances;
    mapping(string => uint256) public teamTokenIds;
    mapping(string => uint256) public teamTokenSupplies;

    string[] private teamNames = [ "ANA", "ARI", "BOS", "BUF", "CGY", "CAR", "CHI", "COL", "CBJ", "DAL", "DET", "EDM", "FLA", "LAK", "MIN", "MTL", "NSH", "NJD", "NYI", "NYR", "OTT", "PHI", "PIT", "SJS", "STL", "TBL", "TOR", "VAN", "VGK", "WSH", "WPG", "SEA"];

    struct Team {
        uint256 totalStaked;
        uint256 treasuryBalance;
        uint256 winBalance;
        uint256 lossBalance;
    }

    uint256 private _gameStartTime;

    constructor(string memory baseURI, address tokenAddress, address treasuryAddress, address aggregatorAddress) ERC1155(baseURI) {
        require(tokenAddress != address(0), "Invalid token address");
        require(treasuryAddress != address(0), "Invalid treasury address");
        require(aggregatorAddress != address(0), "Invalid aggregator address");

        _token = IERC20Metadata(tokenAddress);
        _treasury = treasuryAddress;
        scoreFeed = AggregatorV3Interface(aggregatorAddress);

        for (uint256 i = 0; i < teamNames.length; i++) {
            teamTokenIds[teamNames[i]] = i.add(1);
            teamTokenSupplies[teamNames[i]] = TOTAL_SUPPLY.div(teamNames.length);

            _mint(address(this), i.add(1), teamTokenSupplies[teamNames[i]], "");
        }
    }

    function setGameStartTime(uint256 startTime) external {
        require(msg.sender == _treasury, "Only callable by the treasury");
        require(_gameStartTime == 0, "Game start time already set");
        _gameStartTime = startTime;
    }

    function _getTeamScore(string memory team) private view returns (uint256) {
        (, int256 currentScore, , , ) = scoreFeed.latestRoundData();
        uint256 score = uint256(currentScore).mul(1000);
        uint256 decimals = scoreFeed.decimals();
        if (decimals < 3) {
            score = score.div(10 ** (3 - decimals));
        }
        // Randomize score for demonstration purposes only
score = score.add(uint256(keccak256(abi.encodePacked(team, block.timestamp))) % 1000);
    return score;
}

function distributeRewards(string memory winningTeam, string memory losingTeam) public {
    require(msg.sender == address(this), "Only callable by the contract");
    require(block.timestamp >= _gameStartTime, "Game has not started yet");
    uint256 winningScore;
    uint256 losingScore;
    (winningScore, losingScore) = _getTeamScores(winningTeam, losingTeam);

    uint256 totalStaked = teams[winningTeam].totalStaked.add(teams[losingTeam].totalStaked);
    uint256 winningRatio = winningScore.mul(SCORE_DECIMALS).div(winningScore.add(losingScore));
    uint256 winningReward = totalStaked.mul(winningRatio).div(SCORE_DECIMALS);
    uint256 losingPenalty = totalStaked.sub(winningReward);

    uint256 fee = losingPenalty.mul(5).div(1000); // Calculate the 0.5% fee
    uint256 netLosingPenalty = losingPenalty.sub(fee); // Subtract the fee from the losingPenalty
    _token.transfer(_treasury, netLosingPenalty); // Transfer the net losingPenalty to the treasury

    // Distribute rewards to winning team stakers
    uint256 teamTokenId = teamTokenIds[winningTeam];
    uint256 totalSupply = teamTokenSupplies[winningTeam];
    for (uint256 i = 0; i < _tokenHolders[teamTokenId].length; i++) {
        address holder = _tokenHolders[teamTokenId][i];
        uint256 userStake = stakedBalances[holder][winningTeam];
        uint256 userReward = winningReward.mul(userStake).div(totalStaked);

        if (userReward > 0) {
            teams[winningTeam].treasuryBalance = teams[winningTeam].treasuryBalance.sub(userReward);
            stakedBalances[holder][winningTeam] = 0;

            _token.safeTransferFrom(address(this), holder, teamTokenId, userReward.mul(totalSupply).div(totalStaked), "");
            emit RewardClaimed(holder, winningTeam, userReward);
        }
    }

    // Update team balances
    teams[winningTeam].treasuryBalance = teams[winningTeam].treasuryBalance.add(winningReward);
    teams[losingTeam].treasuryBalance = teams[losingTeam].treasuryBalance.add(losingPenalty);
    teams[winningTeam].winBalance = teams[winningTeam].winBalance.add(winningReward);
    teams[losingTeam].lossBalance = teams[losingTeam].lossBalance.add(losingPenalty);
    teams[winningTeam].totalStaked = 0;
    teams[losingTeam].totalStaked = 0;

    emit RewardsDistributed(winningTeam, losingTeam, winningReward, losingPenalty);
}

function claimReward(string memory team) public {
    require(stakedBalances[msg.sender][team] > 0, "No staked balance for the team");
    uint256 userStake = stakedBalances[msg.sender][team];
    uint256 userReward = teams[team].treasuryBalance.mul(userStake).div(teams[team].winBalance);
    require(userReward > 0, "No rewards available for the team");

    teams[team].treasuryBalance = teams[team].treasuryBalance.sub(userReward);
    teams[team].winBalance = teams[team].winBalance.sub(userStake);
stakedBalances[msg.sender][team] = 0;
    _token.transfer(msg.sender, userReward);
    emit RewardClaimed(msg.sender, team, userReward);
}

function stake(uint256 amount, string memory team) public {
    require(amount > 0, "Cannot stake 0 amount");
    require(teams[team].totalStaked > 0, "Invalid team name");

    uint256 tokenId = teamTokenIds[team];

    _token.transferFrom(msg.sender, address(this), amount);
    _burn(msg.sender, tokenId, amount);

    if (stakedBalances[msg.sender][team] == 0) {
        _tokenHolders[tokenId].push(msg.sender);
    }

    stakedBalances[msg.sender][team] = stakedBalances[msg.sender][team].add(amount);
    teams[team].totalStaked = teams[team].totalStaked.add(amount);

    emit Staked(msg.sender, team, amount);
}

function unstake(string memory team) public {
    require(stakedBalances[msg.sender][team] > 0, "No staked balance for the team");

    uint256 amount = stakedBalances[msg.sender][team];
    uint256 tokenId = teamTokenIds[team];

    stakedBalances[msg.sender][team] = 0;
    teams[team].totalStaked = teams[team].totalStaked.sub(amount);

    _token.transfer(msg.sender, amount);
    _mint(msg.sender, tokenId, amount, "");

    emit Unstaked(msg.sender, team, amount);
}

function getStakedBalance(address user, string memory team) public view returns (uint256) {
    return stakedBalances[user][team];
}

function _getTeamScores(string memory teamA, string memory teamB) private view returns (uint256, uint256) {
    uint256 teamAScore = _getTeamScore(teamA);
    uint256 teamBScore = _getTeamScore(teamB);
    return (teamAScore, teamBScore);
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
}



