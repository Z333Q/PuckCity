// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract HockeyPool is ERC1155("https://example.com/token/{id}.json"), ERC20("HockeyPool Token", "HP") {
    using SafeMath for uint256;

    AggregatorV3Interface public scoreFeed;

    struct Team {
        uint256 totalStaked;
        uint256 treasuryBalance;
        uint256 winBalance;
        uint256 lossBalance;
    }

    mapping(string => Team) public teams;
    mapping(address => mapping(string => uint256)) public stakedBalances;
    mapping(string => uint256) public teamTokenIds;
    mapping(string => uint256) public teamTokenSupplies;

    string[] private teamNames = [        "ANA",        "ARI",        "BOS",        "BUF",        "CGY",        "CAR",        "CHI",        "COL",        "CBJ",        "DAL",        "DET",        "EDM",        "FLA",        "LAK",        "MIN",        "MTL",        "NSH",        "NJD",        "NYI",        "NYR",        "OTT",        "PHI",        "PIT",        "SJS",        "STL",        "TBL",        "TOR",        "VAN",        "VGK",        "WSH",        "WPG"    ];

    constructor(address _aggregatorAddress) {
        scoreFeed = AggregatorV3Interface(_aggregatorAddress);
    }

    function stakeTeam(string memory team, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");

        stakedBalances[msg.sender][team] = stakedBalances[msg.sender][team].add(amount);
        teams[team].totalStaked = teams[team].totalStaked.add(amount);

        if (teamTokenSupplies[team] == 0) {
            teamTokenIds[team] = teamNames.indexOf(team);
            _mint(address(this), teamTokenIds[team], 10000, "");
            teamTokenSupplies[team] = 10000;
        }

        _mint(msg.sender, teamTokenIds[team], amount, "");

        emit TeamStaked(msg.sender, team, amount);
    }

    function unstakeTeam(string memory team, uint256 amount) public {
        require(stakedBalances[msg.sender][team] >= amount, "Not enough staked balance");

        stakedBalances[msg.sender][team] = stakedBalances[msg.sender][team].sub(amount);
        teams[team].totalStaked = teams[team].totalStaked.sub(amount);

        _burn(msg.sender, teamTokenIds[team], amount);

        emit TeamUnstaked(msg.sender, team, amount);
    }

    function distributeRewards(string memory winningTeam, string memory losingTeam) public {
        require(msg.sender == address(this), "Only callable by the contract");

        uint256 winningScore;
        uint256 losingScore;
        (winningScore, losingScore) = _getTeamScores(winningTeam, losingTeam);

        uint256 totalStaked = teams[winningTeam].totalStaked.add(teams[losingTeam].totalStaked);
        // Calculate rewards and penalties
uint256 winningReward = totalStaked.mul(winningScore).div(winningScore.add(losingScore));
uint256 losingPenalty = totalStaked.sub(winningReward);
    // Update team balances
    teams[winningTeam].treasuryBalance = teams[winningTeam].treasuryBalance.add(winningReward);
    teams[losingTeam].lossBalance = teams[losingTeam].lossBalance.add(losingPenalty);

    // Iterate over staked balances for winning team and distribute rewards
    for (uint256 i = 0; i < _holders[winningTeam].length; i++) {
        address holder = _holders[winningTeam][i];
        uint256 userStake = stakedBalances[holder][winningTeam];

        if (userStake > 0) {
            uint256 rewardAmount = winningReward.mul(userStake).div(teams[winningTeam].totalStaked);

            // Update user's balance and team's win balance
            stakedBalances[holder][winningTeam] = stakedBalances[holder][winningTeam].add(rewardAmount);
            teams[winningTeam].winBalance = teams[winningTeam].winBalance.add(rewardAmount);

            emit RewardClaimed(holder, winningTeam, rewardAmount);
        }
    }

    // Reset staked balances for both teams
    teams[winningTeam].totalStaked = 0;
    teams[losingTeam].totalStaked = 0;

    emit RewardsDistributed(winningTeam, losingTeam, winningReward, losingPenalty);
}

function claimReward(string memory team) public {
    require(stakedBalances[msg.sender][team] > 0, "No staked balance for the team");

    uint256 userStake = stakedBalances[msg.sender][team];
    uint256 rewardAmount = teams[team].treasuryBalance.mul(userStake).div(teams[team].totalStaked);

    // Update user's balance and team's treasury balance
    stakedBalances[msg.sender][team] = 0;
    teams[team].treasuryBalance = teams[team].treasuryBalance.sub(rewardAmount);

    // Transfer ERC20 tokens to user
    require(token.transfer(msg.sender, rewardAmount), "Transfer failed");

    emit RewardClaimed(msg.sender, team, rewardAmount);
}

function getTeamTreasuryBalance(string memory team) public view returns (uint256) {
    return teams[team].treasuryBalance;
}

function getTeamWinBalance(string memory team) public view returns (uint256) {
    return teams[team].winBalance;
}

function getTeamLossBalance(string memory team) public view returns (uint256) {
    return teams[team].lossBalance;
}

function getUserStakedBalance(address user, string memory team) public view returns (uint256) {
    return stakedBalances[user][team];
}

function getTeamTokenId(string memory team) public view returns (uint256) {
    return teamTokenIds[team];
}

function getTeamTokenSupply(string memory team) public view returns (uint256) {
    return teamTokenSupplies[team];
}
event TeamStaked(address indexed user, string team, uint256 amount);
event TeamUnstaked(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event RewardClaimed(address indexed user, string team, uint256 amount);
