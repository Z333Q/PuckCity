// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract StakingContract is ERC1155, Ownable {
    uint256 constant MAX_TOKENS_PER_TEAM = 1000;

    AggregatorV3Interface public scoreFeed;

    struct Team {
        uint256 totalStaked;
        uint256 treasuryBalance;
        uint256 winBalance;
        uint256 lossBalance;
        uint256 drawBalance;
    }

    mapping(string => Team) public teams;
    mapping(address => mapping(string => uint256)) public stakedBalances;
    mapping(string => uint256) public teamTokenIds;
    mapping(string => uint256) public teamTokenSupplies;

    string[] private teamNames = [
        "ANA",
        "ARI",
        "BOS",
        "BUF",
        "CGY",
        "CAR",
        "CHI",
        "COL",
        "CBJ",
        "DAL",
        "DET",
        "EDM",
        "FLA",
        "LAK",
        "MIN",
        "MTL",
        "NSH",
        "NJD",
        "NYI",
        "NYR",
        "OTT",
        "PHI",
        "PIT",
        "SJS",
        "STL",
        "TBL",
        "TOR",
        "VAN",
        "VGK",
        "WSH"
    ];

    constructor(address aggregator) ERC1155("") {
        setScoreFeed(aggregator);
        for (uint256 i = 0; i < 32; i++) {
            uint256 tokenId = i + 1;
            string memory team = teamNames[i];
            teamTokenIds[team] = tokenId;
            teamTokenSupplies[team] = MAX_TOKENS_PER_TEAM;
            _mint(msg.sender, tokenId, MAX_TOKENS_PER_TEAM, "");
        }
    }

    function setScoreFeed(address aggregator) public onlyOwner {
        scoreFeed = AggregatorV3Interface(aggregator);
    }

    function getLastGameTimestamp(string memory team) public view returns (uint256) {
        uint256 currentTimestamp = block.timestamp;
        (, int256 score, , uint256 scoreTimestamp, ) = scoreFeed.latestRoundData();
        int256 lastScore = getTeamScore(team, score, currentTimestamp);
        for (uint256 i = 0; i < 82; i++) {
            (int256 homeScore, int256 awayScore) = getGameScore(team, i + 1);
            if (homeScore != 0 || awayScore != 0) {
                uint256 gameStartTime = getGameStartTime(getCurrentSeason()[0], i + 1);
                if (gameStartTime < currentTimestamp && lastScore != homeScore && lastScore != awayScore) {
                    return scoreTimestamp;
                }
            }
        }
        return 0;
    }

    function stake(string memory team, uint256 amount) external {
        require(keccak256(bytes(team)) != keccak256(bytes("")), "Invalid team name");
        require(amount > 0, "Invalid amount");
        require(teamTokenSupplies[team] >= amount, "Insufficient tokens");
        uint256 tokenId = teamTokenIds[team];
        IERC20(tokenId).transferFrom(msg.sender, address(this), amount);
stakedBalances[msg.sender][team] += amount;
Team storage teamInfo = teams[team];
teamInfo.totalStaked += amount;
teamTokenSupplies[team] -= amount;
emit Staked(msg.sender, team, amount);
}
function unstake(string memory team, uint256 amount) external {
    require(keccak256(bytes(team)) != keccak256(bytes("")), "Invalid team name");
    require(amount > 0, "Invalid amount");
    uint256 stakedAmount = stakedBalances[msg.sender][team];
    require(stakedAmount >= amount, "Insufficient staked balance");
    Team storage teamInfo = teams[team];
    IERC20(tokenId).transfer(msg.sender, amount);
    stakedBalances[msg.sender][team] -= amount;
    teamInfo.totalStaked -= amount;
    teamTokenSupplies[team] += amount;
    emit Unstaked(msg.sender, team, amount);
}

function distribute(uint256 year, uint256 gameNumber) external {
    require(gameNumber > 0 && gameNumber <= 82, "Invalid game number");
    require(block.timestamp >= getGameDistributeTime(year, gameNumber), "Distribution time not reached");
    string memory homeTeam = parseString(gameData[year][gameNumber], 2);
    string memory awayTeam = parseString(gameData[year][gameNumber], 3);
    int256 homeScore = parseInt(parseString(gameData[year][gameNumber], 6));
    int256 awayScore = parseInt(parseString(gameData[year][gameNumber], 7));
    Team storage homeTeamInfo = teams[homeTeam];
    Team storage awayTeamInfo = teams[awayTeam];
    if (homeScore > awayScore) {
        homeTeamInfo.winBalance += 1;
        awayTeamInfo.lossBalance += 1;
    } else if (homeScore < awayScore) {
        homeTeamInfo.lossBalance += 1;
        awayTeamInfo.winBalance += 1;
    } else {
        homeTeamInfo.tieBalance += 1;
        awayTeamInfo.tieBalance += 1;
    }
    emit Distributed(year, gameNumber, homeTeam, awayTeam, homeScore, awayScore);
}

function getGameData(uint256 year, uint256 gameNumber) public view returns (string memory) {
    return gameData[year][gameNumber];
}

function setGameData(uint256 year, uint256 gameNumber, string memory data) external onlyOwner {
    gameData[year][gameNumber] = data;
}

function setScoreFeed(address aggregator) external onlyOwner {
    scoreFeed = AggregatorV3Interface(aggregator);
}

function getLastGameTimestamp(string memory team) public view returns (uint256) {
    uint256 currentTimestamp = block.timestamp;
    (, int256 score, , uint256 scoreTimestamp, ) = scoreFeed.latestRoundData();
    int256 lastScore = getTeamScore(team, score, currentTimestamp);
    for (uint256 i = 0; i < 82; i++) {
        (int256 homeScore, int256 awayScore) = getGameScore(team, i + 1);
        if (homeScore != 0 || awayScore != 0) {
            uint256 gameStartTime = getGameStartTime(getCurrentSeason()[0], i + 1);
            if (gameStartTime > scoreTimestamp) {
                break;
            }
            lastScore = getTeamScore(team, score, gameStartTime);
        }
    }
    return lastScore == 0 ? currentTimestamp : scoreTimestamp;
}

function getGameScore(string memory team, uint256 gameNumber) public view returns (int256, int256) {
(uint256 year, , ) = getCurrentSeason();
uint256 startTime = getSeasonStartTime(year);
uint256 gameStartTime = startTime + (gameNumber - 1) * 1 days;
if (block.timestamp < gameStartTime) {
return (0, 0);
}
string memory gameData = getGameData(year, gameNumber);
string memory homeTeam = parseString(gameData, 2);
string memory awayTeam = parseString(gameData, 3);
require(keccak256(bytes(homeTeam)) == keccak256(bytes(team)) || keccak256(bytes(awayTeam)) == keccak256(bytes(team)), "Team not in game");
int256 homeScore = parseInt(parseString(gameData, 6));
int256 awayScore = parseInt(parseString(gameData, 7));
if (keccak256(bytes(homeTeam)) != keccak256(bytes(team))) {
(homeScore, awayScore) = (awayScore, homeScore);
}
return (homeScore, awayScore);
}
function getCurrentSeason() public view returns (uint256, uint256, uint256) {
uint256 timestamp = block.timestamp;
if (timestamp < 1640995200) { // 2022-2023 season start time
return (2022, 9, 1);
} else {
uint256 year = 2022;
uint256 day = 1;
while (timestamp >= getSeasonStartTime(year + 1)) {
year++;
day = (timestamp - getSeasonStartTime(year)) / 1 days + 1;
}
return (year, day, getSeasonStartTime(year));
}
}

function getSeasonStartTime(uint256 year) public pure returns (uint256) {
require(year >= 2022, "Invalid year");
uint256 unixTimestamp = 1640995200; // 2022-2023 season start time
for (uint256 i = 2022; i < year; i++) {
unixTimestamp += isLeapYear(i) ? 31622400 : 31536000;
}
return unixTimestamp;
}

function isLeapYear(uint256 year) public pure returns (bool) {
if (year % 4 != 0) {
return false;
} else if (year % 100 != 0) {
return true;
} else if (year % 400 != 0) {
return false;
} else {
return true;
}
}

function parseString(string memory str, uint256 field) internal pure returns (string memory) {
bytes memory bytesStr = bytes(str);
uint256 startIndex = 0;
uint256 endIndex = 0;
uint256 index = 0;
while (index <= field && endIndex < bytesStr.length) {
if (bytesStr[endIndex] == ",") {
if (index == field) {
break;
} else {
startIndex = endIndex + 1;
index++;
}
}
endIndex++;
}
require(endIndex < bytesStr.length, "Invalid field index");
return string(bytesStr[startIndex:endIndex]);
}

function parseInt(string memory str) internal pure returns (int256) {
bytes memory bytesStr = bytes(str);
int256 result = 0;
bool negative = false;
uint256 i = 0;
if (bytesStr[0] == "-") {
negative = true;
i = 1;
}
for (; i < bytesStr.length; i++) {
uint8 digit = uint8(bytesStr[i]) - 48;
require(digit <= 9, "Invalid number string");
result = result * 10 + int256(digit);
}
if (negative) {
result = -result;
}
return result;
}

function getTeamScore(string memory team, int256 score, uint256 timestamp) internal view returns (int256) {
if (keccak256(bytes(team)) == keccak256(bytes("ANA"))) {
return (score / 10000000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("ARI"))) {
return (score / 10000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("BOS"))) {
return (score / 1000000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("BUF"))) {
return (score / 100000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("CGY"))) {
return (score / 1000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("CAR"))) {
return (score / 100000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("CHI"))) {
return (score / 10000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("COL"))) {
return (score / 100000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("CBJ"))) {
return (score / 100000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("DAL"))) {
return (score / 10000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("DET"))) {
return (score / 100000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("EDM"))) {
return (score / 100000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("FLA"))) {
return (score / 100000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("LAK"))) {
return (score / 100000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("MIN"))) {
return (score / 1000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("MTL"))) {
return (score / 100000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("NSH"))) {
return (score / 1000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("NJD"))) {
return (score / 10000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("NYI"))) {
return (score / 10000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("NYR"))) {
return (score / 10000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("OTT"))) {
return (score / 1000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("PHI"))) {
return (score / 10000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("PIT"))) {
return (score / 100000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("SJS"))) {
return (score / 100000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("STL"))) {
return (score / 10000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("TBL"))) {
return (score / 10000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("TOR"))) {
return (score / 100000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("VAN"))) {
return (score / 10000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("VGK"))) {
return (score / 10000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("WSH"))) {
return (score / 10000000000) % 100;
} else if (keccak256(bytes(team)) == keccak256(bytes("WPG"))) {
return (score / 1000000) % 100;
} else {
revert("Invalid team name");
}
}

function getSeasonStartTime(uint256 year) internal pure returns (uint256) {
uint256[4] memory seasonStartTimes = [uint256(1573689600), 1605225600, 1636761600, 1668297600];
require(year >= 2020 && year <= 2023, "Invalid year");
return seasonStartTimes[year - 2020];
}

function getCurrentSeason() public view returns (uint256[2] memory) {
uint256 currentTimestamp = block.timestamp;
if (currentTimestamp >= getSeasonStartTime(2023)) {
return [2023, 4];
} else if (currentTimestamp >= getSeasonStartTime(2022)) {
return [2022, 3];
} else if (currentTimestamp >= getSeasonStartTime(2021)) {
return [2021, 2];
} else {
return [2020, 1];
}
}

function getGameStartTime(uint256 year, uint256 gameNumber) internal pure returns (uint256) {
uint256 startTime = getSeasonStartTime(year);
return startTime + (gameNumber - 1) * 1 days;
}

function getGameDistributeTime(uint256 year, uint256 gameNumber) internal pure returns (uint256) {
uint256 gameStartTime = getGameStartTime(year, gameNumber);
return gameStartTime + 24 hours;
}

function setURI(string memory newUri) public onlyOwner {
_setURI(newUri);
}
}


