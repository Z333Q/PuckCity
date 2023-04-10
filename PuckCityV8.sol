// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/PolygonCompatibleERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/metatx/ForwarderRegistry.sol";
import "@openzeppelin/contracts/metatx/UserOperation.sol";
import "@openzeppelin/contracts/metatx/UserOperationEvents.sol";

contract PuckCityV7 is PolygonCompatibleERC1155, VRFConsumerBase, Ownable, UserOperationEvents {

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

        ForwarderRegistry forwarderRegistry = ForwarderRegistry(0x1234...);
        // Replace with actual forwarderRegistry address
        forwarderRegistry.registerForwarder(address(this));

        _token = IERC20Metadata(tokenAddress);
        _treasury = treasuryAddress;
        scoreFeed = AggregatorV3Interface(aggregatorAddress);

        for (uint256 i = 0; i < teamNames.length; i++) {
            teamTokenIds[teamNames[i]] = i.add(1);
            teamTokenSupplies[teamNames[i]] = TOTAL_SUPPLY.div(teamNames.length);

            _mint(address(this), i.add(1), teamTokenSupplies[teamNames[i]], "");
        }
    }

function handleOps(UserOperation[] calldata ops, address payable origin) external override {
    for (uint256 i = 0; i < ops.length; i++) {
        if (ops[i].opType == UserOperation.OpType.Call) {function handleOps(UserOperation[] calldata ops, address payable origin) external override {
for (uint256 i = 0; i < ops.length; i++) {
if (ops[i].opType == UserOperation.OpType.Call) {
handleCallOps(ops[i], origin);
} else if (ops[i].opType == UserOperation.OpType.Balance) {
handleBalanceOps(ops[i]);
}
}
}

function handleBalanceOps(UserOperation calldata op) internal {
require(op.sender == address(this), "Invalid sender");
require(op.receiver != address(0), "Invalid receiver");
uint256 tokenId = uint256(op.tokenId);
uint256 amount = uint256(op.amount);

_safeTransferFrom(address(this), op.receiver, tokenId, amount, "");
}

function handleCallOps(UserOperation calldata op, address payable origin) internal {
bytes4 selector = abi.decode(op.data, (bytes4));
require(selector == this.stake.selector || selector == this.unstake.selector, "Invalid function selector");

if (selector == this.stake.selector) {
    (uint256 amount, string memory team) = abi.decode(op.data[4:], (uint256, string));
    stakeFrom(origin, amount, team);
} else if (selector == this.unstake.selector) {
    (string memory team) = abi.decode(op.data[4:], (string));
    unstakeFrom(origin, team);
}
}

function stakeFrom(address user, uint256 amount, string memory team) internal {
require(amount > 0, "Cannot stake 0 amount");
require(teams[team].totalStaked > 0, "Invalid team name");
uint256 tokenId = teamTokenIds[team];

_token.transferFrom(user, address(this), amount);
_burn(user, tokenId, amount);

if (stakedBalances[user][team] == 0) {
    _tokenHolders[tokenId].push(user);
}

stakedBalances[user][team] = stakedBalances[user][team].add(amount);
teams[team].totalStaked = teams[team].totalStaked.add(amount);

emit Staked(user, team, amount);
}

function unstakeFrom(address user, string memory team) internal {
require(stakedBalances[user][team] > 0, "No staked balance for the team");
uint256 amount = stakedBalances[user][team];
uint256 tokenId = teamTokenIds[team];

uint256 fee = amount.div(100); // Calculate the 1% fee
uint256 netAmount = amount.sub(fee); // Subtract the fee from the amount
stakedBalances[user][team] = 0;
teams[team].totalStaked = teams[team].totalStaked.sub(amount);

teams[team].treasuryBalance = teams[team].treasuryBalance.add(fee); // Add the fee to the treasury balance
_token.transfer(user, netAmount);
_mint(user, tokenId, netAmount, "");

emit Unstaked(user, team, netAmount);
}
function claimTreasuryBalance(string memory team) external {
require(msg.sender == teams[team].admin, "Only team admin can claim treasury balance");
require(teams[team].treasuryBalance > 0, "No treasury balance to claim");
uint256 amount = teams[team].treasuryBalance;
teams[team].treasuryBalance = 0;
_token.transfer(msg.sender, amount);

emit TreasuryBalanceClaimed(msg.sender, team, amount);
}

function getStakedBalance(address user, string memory team) public view returns (uint256) {
return stakedBalances[user][team];
}

function getTeamTotalStaked(string memory team) public view returns (uint256) {
return teams[team].totalStaked;
}

function getTeamTreasuryBalance(string memory team) public view returns (uint256) {
return teams[team].treasuryBalance;
}

function getUserTokenHolding(address user, uint256 tokenId) public view returns (uint256) {
return _balances[tokenId][user];
}

function getTokenHolders(uint256 tokenId) public view returns (address[] memory) {
return _tokenHolders[tokenId];
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function getTeamWinBalance(string memory team) public view returns (uint256) {
return teams[team].winBalance;
}

function getTeamLossBalance(string memory team) public view returns (uint256) {
return teams[team].lossBalance;
}

function getTotalSupply(string memory team) public view returns (uint256) {
return teamTokenSupplies[team];
}

function getTeamTokenId(string memory team) public view returns (uint256) {
return teamTokenIds[team];
}

function getTeamName(uint256 tokenId) public view returns (string memory) {
for (uint256 i = 0; i < teamNames.length; i++) {
if (teamTokenIds[teamNames[i]] == tokenId) {
return teamNames[i];
}
}
return "";
}

function getAllTeamNames() public view returns (string[] memory) {
return teamNames;
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function distributeRewards(string memory winningTeam, string memory losingTeam) public onlyAdmin {
require(bytes(winningTeam).length > 0, "Winning team name is required");
require(bytes(losingTeam).length > 0, "Losing team name is required");
require(keccak256(abi.encodePacked(winningTeam)) != keccak256(abi.encodePacked(losingTeam)), "Winning and losing teams must be different");
 Team storage winTeam = teams[winningTeam];
Team storage loseTeam = teams[losingTeam];

uint256 winningReward = winTeam.totalStaked.div(100); // Calculate the 1% reward for the winning team
uint256 losingPenalty = loseTeam.totalStaked.div(100); // Calculate the 1% penalty for the losing team

// Update the winning and losing team's balances
winTeam.winBalance = winTeam.winBalance.add(winningReward);
loseTeam.lossBalance = loseTeam.lossBalance.add(losingPenalty);

// Update the total staked balances for both teams
winTeam.totalStaked = winTeam.totalStaked.add(winningReward);
loseTeam.totalStaked = loseTeam.totalStaked.sub(losingPenalty);

emit RewardsDistributed(winningTeam, losingTeam, winningReward, losingPenalty);
}

function claimReward(address user, string memory team) public {
Team storage userTeam = teams[team];
uint256 userStakedAmount = stakedBalances[user][team];
require(userStakedAmount > 0, "User has no staked balance in this team");

uint256 userReward = userTeam.winBalance.mul(userStakedAmount).div(userTeam.totalStaked);

userTeam.winBalance = userTeam.winBalance.sub(userReward);
userTeam.totalStaked = userTeam.totalStaked.add(userReward);
stakedBalances[user][team] = userStakedAmount.add(userReward);

emit RewardClaimed(user, team, userReward);
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function claimTreasuryBalance(address payable admin, string memory team) public onlyAdmin {
Team storage teamData = teams[team];
require(teamData.treasuryBalance > 0, "Treasury balance is empty");

uint256 treasuryBalance = teamData.treasuryBalance;
teamData.treasuryBalance = 0;

admin.transfer(treasuryBalance);

emit TreasuryBalanceClaimed(admin, team, treasuryBalance);
}

function isAdmin(address user) public view returns (bool) {
return _admins[user];
}

function addAdmin(address newAdmin) public onlyAdmin {
_admins[newAdmin] = true;
}

function removeAdmin(address adminToRemove) public onlyAdmin {
_admins[adminToRemove] = false;
}

modifier onlyAdmin() {
require(isAdmin(msg.sender), "Caller is not an admin");
_;
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function distributeRewards(string memory winningTeam, string memory losingTeam) public onlyAdmin {
Team storage winningTeamData = teams[winningTeam];
Team storage losingTeamData = teams[losingTeam];
require(winningTeamData.totalStaked > 0, "Winning team has no staked amount");
require(losingTeamData.totalStaked > 0, "Losing team has no staked amount");

uint256 winningReward = losingTeamData.totalStaked.mul(.5).div(100); // .5% of the losing team's staked amount
uint256 losingPenalty = losingTeamData.totalStaked.mul(.5).div(100); // .5% of the losing team's staked amount

winningTeamData.totalStaked = winningTeamData.totalStaked.add(winningReward);
losingTeamData.totalStaked = losingTeamData.totalStaked.sub(losingPenalty);

winningTeamData.rewardPool = winningTeamData.rewardPool.add(winningReward);
losingTeamData.penaltyPool = losingTeamData.penaltyPool.add(losingPenalty);

emit RewardsDistributed(winningTeam, losingTeam, winningReward, losingPenalty);
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function getRewardPool(string memory team) public view returns (uint256) {
return teams[team].rewardPool;
}

function getPenaltyPool(string memory team) public view returns (uint256) {
return teams[team].penaltyPool;
}

function getTeamTotalStaked(string memory team) public view returns (uint256) {
return teams[team].totalStaked;
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function getStakedBalance(address user, string memory team) public view returns (uint256) {
return stakedBalances[user][team];
}

function getUserReward(address user, string memory team) public view returns (uint256) {
return userRewards[user][team];
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function isTeam(string memory team) public view returns (bool) {
for (uint256 i = 0; i < teamNames.length; i++) {
if (keccak256(abi.encodePacked(teamNames[i])) == keccak256(abi.encodePacked(team))) {
return true;
}
}
return false;
}

function getNumberOfTeams() public view returns (uint256) {
return teamNames.length;
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function getTotalTokensMinted() public view returns (uint256) {
uint256 totalTokens = 0;
for (uint256 i = 0; i < teamNames.length; i++) {
totalTokens = totalTokens.add(_totalSupply[teamTokenIds[teamNames[i]]]);
}
return totalTokens;
}

function getTeamTokenId(string memory team) public view returns (uint256) {
return teamTokenIds[team];
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function getTreasuryBalanceOfAllTeams() public view returns (uint256[] memory) {
uint256[] memory treasuryBalances = new uint256;
for (uint256 i = 0; i < teamNames.length; i++) {
treasuryBalances[i] = teams[teamNames[i]].treasuryBalance;
}
return treasuryBalances;
}

function getAdmins() public view returns (address[] memory) {
return admins;
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function getTotalStakedOfAllTeams() public view returns (uint256[] memory) {
uint256[] memory totalStaked = new uint256;
for (uint256 i = 0; i < teamNames.length; i++) {
totalStaked[i] = teams[teamNames[i]].totalStaked;
}
return totalStaked;
}

function getTeamUsers(string memory team) public view returns (address[] memory) {
return teamUsers[team];
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function getUserStakedBalanceForTeam(address user, string memory team) public view returns (uint256) {
return stakedBalances[user][team];
}

function isUserPartOfTeam(address user, string memory team) public view returns (bool) {
for (uint256 i = 0; i < teamUsers[team].length; i++) {
if (teamUsers[team][i] == user) {
return true;
}
}
return false;
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function getTotalStaked() public view returns (uint256) {
uint256 totalStakedAmount = 0;
for (uint256 i = 0; i < teamNames.length; i++) {
totalStakedAmount = totalStakedAmount.add(teams[teamNames[i]].totalStaked);
}
return totalStakedAmount;
}

function getNumberOfUsersInTeam(string memory team) public view returns (uint256) {
return teamUsers[team].length;
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function getTeamUserStake(address user, string memory team) public view returns (uint256) {
return stakedBalances[user][team];
}

function isUserAdmin(address user) public view returns (bool) {
for (uint256 i = 0; i < admins.length; i++) {
if (admins[i] == user) {
return true;
}
}
return false;
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function getTeamUserRewards(address user) public view returns (mapping(string => uint256) storage) {
return userRewards[user];
}

function getAllTeamsInfo() public view returns (TeamInfo[] memory) {
TeamInfo[] memory allTeamsInfo = new TeamInfo;
for (uint256 i = 0; i < teamNames.length; i++) {
    string memory team = teamNames[i];
    allTeamsInfo[i] = TeamInfo({
        name: team,
        tokenId: teamTokenIds[team],
        totalStaked: teams[team].totalStaked,
        treasuryBalance: teams[team].treasuryBalance,
        numberOfUsers: teamUsers[team].length
    });
}

return allTeamsInfo;
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
}
function getRewardDistributionInfo() public view returns (uint256, uint256) {
return (winningTeamRewardPercentage, losingTeamPenaltyPercentage);
}

function setRewardDistributionInfo(uint256 _winningTeamRewardPercentage, uint256 _losingTeamPenaltyPercentage) external onlyAdmin {
require(_winningTeamRewardPercentage > 0 && _winningTeamRewardPercentage <= 100, "Invalid winning team reward percentage");
require(_losingTeamPenaltyPercentage >= 0 && _losingTeamPenaltyPercentage <= 100, "Invalid losing team penalty percentage");
winningTeamRewardPercentage = _winningTeamRewardPercentage;
losingTeamPenaltyPercentage = _losingTeamPenaltyPercentage;

emit RewardDistributionInfoUpdated(_winningTeamRewardPercentage, _losingTeamPenaltyPercentage);
}

event Staked(address indexed user, string team, uint256 amount);
event Unstaked(address indexed user, string team, uint256 amount);
event RewardClaimed(address indexed user, string team, uint256 amount);
event RewardsDistributed(string winningTeam, string losingTeam, uint256 winningReward, uint256 losingPenalty);
event TreasuryBalanceClaimed(address indexed admin, string team, uint256 amount);
event RewardDistributionInfoUpdated(uint256 winningTeamRewardPercentage, uint256 losingTeamPenaltyPercentage);
}


          
