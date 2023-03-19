pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PuckCity is ERC1155Holder, Ownable {
using SafeMath for uint256;
using Counters for Counters.Counter;
IERC20 public paymentToken;
IERC1155 public teamTokens;
Counters.Counter private _tokenIdCounter;
uint256 public constant PERCENTAGE_BASE = 10000;
uint256 public constant TOKENS_PER_TEAM = 1000;
uint256 public constant TOKEN_VALUE_BASE = 1 ether;
uint256 public constant PRICE_START = 200000000000000000;
uint256 public constant PRICE_MULTIPLIER = 1333333333333333;
uint256 public constant MAX_FEE = 500; // 5%
uint256 public fee = 50; // 0.5%
uint256 public reserveRatio = 5000; // 50%
uint256 public reserveBalance;
uint256 public globalTreasury;
mapping(uint256 => GameResult) public gameResults;
mapping(uint256 => uint256) public teamTreasury;

struct GameResult {
    uint256 teamIndexA;
    uint256 teamIndexB;
    uint256 scoreA;
    uint256 scoreB;
}

constructor(IERC20 _paymentToken, IERC1155 _teamTokens) {
    paymentToken = _paymentToken;
    teamTokens = _teamTokens;
}

function buyPuckCityToken(uint256 _amount) external {
    require(_amount > 0, "Invalid amount.");
    uint256 ethAmount = calculateTokenPrice(_amount);
    uint256 feeAmount = ethAmount.mul(fee).div(PERCENTAGE_BASE);
    reserveBalance += feeAmount;
    globalTreasury += ethAmount.sub(feeAmount);
    require(paymentToken.balanceOf(address(msg.sender)) >= ethAmount, "Insufficient payment token balance.");
    paymentToken.safeTransferFrom(msg.sender, address(this), ethAmount.mul(1 ether));
}

function getTeamToken(uint256 _teamIndex) public pure returns (uint256) {
    return _teamIndex.mul(TOKENS_PER_TEAM);
}

function buyTeamToken(uint256 _teamIndex, uint256 _amount) external {
    require(_teamIndex < 32, "Invalid team index.");
    require(_amount > 0, "Invalid amount.");
    uint256 teamTokenStart = getTeamToken(_teamIndex);
    uint256 teamTokenEnd = teamTokenStart.add(TOKENS_PER_TEAM);
    uint256 tokenIdStart = _tokenIdCounter.current();
    uint256 tokenIdEnd = tokenIdStart.add(_amount);
    uint256 ethAmount = calculateTokenPrice(_amount);
    uint256 feeAmount = ethAmount.mul(fee).div(PERCENTAGE_BASE);
    reserveBalance += feeAmount;
    globalTreasury += ethAmount.sub(feeAmount);
    require(paymentToken.balanceOf(address(msg.sender)) >= ethAmount, "Insufficient payment token balance.");
    paymentToken.safeTransferFrom(address(msg.sender), address(this), ethAmount);
    for (uint256 i = tokenIdStart; i < tokenIdEnd; i++) {
        uint256 tokenId = i;
        uint256 tokenTeamIndex = tokenId.div(TOKENS_PER_TEAM);
               require(tokenTeamIndex == _teamIndex, "Invalid team token.");
        require(tokenId < teamTokenEnd, "Invalid team token.");
        teamTokens.safeTransferFrom(address(this), msg.sender, teamTokens.idToType(teamTokenStart), 1, "");
    }
    _tokenIdCounter.increment(_amount);
}

function setGameResult(
    uint256 _gameIndex,
    uint256 _teamIndexA,
    uint256 _teamIndexB,
    uint256 _scoreA,
    uint256 _scoreB
) external onlyOwner {
    require(_gameIndex < 1230, "Invalid game index.");
    require(_teamIndexA < 32, "Invalid team A index.");
    require(_teamIndexB < 32, "Invalid team B index.");
    require(_scoreA >= 0, "Invalid score A.");
    require(_scoreB >= 0, "Invalid score B.");
    GameResult storage gameResult = gameResults[_gameIndex];
    require(gameResult.teamIndexA == 0, "Game result already set.");
    gameResult.teamIndexA = _teamIndexA;
    gameResult.teamIndexB = _teamIndexB;
    gameResult.scoreA = _scoreA;
    gameResult.scoreB = _scoreB;
    if (_scoreA > _scoreB) {
        _distribute(_teamIndexA, _teamIndexB, _scoreA, _scoreB);
    } else if (_scoreA < _scoreB) {
        _distribute(_teamIndexB, _teamIndexA, _scoreB, _scoreA);
    }
}

function distributeAll() external {
    uint256[] memory teamScores = new uint256[](32);
    (uint256 scoreA, uint256 scoreB) = _calculateTotalScore(teamScores);
    for (uint256 i = 0; i < 1230; i++) {
        GameResult storage gameResult = gameResults[i];
        if (gameResult.teamIndexA == 0) continue;
        if (gameResult.scoreA > gameResult.scoreB) {
            _distribute(gameResult.teamIndexA, gameResult.teamIndexB, gameResult.scoreA, gameResult.scoreB);
        } else if (gameResult.scoreA < gameResult.scoreB) {
            _distribute(gameResult.teamIndexB, gameResult.teamIndexA, gameResult.scoreB, gameResult.scoreA);
        }
    }
    for (uint256 i = 0; i < 32; i++) {
        uint256 teamScore = teamScores[i];
        if (teamScore == 0) continue;
        uint256 reserveAmount = teamScore.mul(reserveRatio).div(PERCENTAGE_BASE);
        reserveBalance += reserveAmount;
        uint256 teamTreasuryAmount = teamScore.sub(reserveAmount);
        teamTreasury[i] += teamTreasuryAmount;
    }
    globalTreasury = 0;
}

function _distribute(
    uint256 _winnerTeamIndex,
    uint256 _loserTeamIndex,
    uint256 _winnerScore,
    uint256 _loserScore
) private {
    uint256 winnerTokenStart = getTeamToken(_winnerTeamIndex);
    uint256 loserTokenStart = getTeamToken(_loserTeamIndex);
    for (uint256 i = 0; i < TOKENS_PER_TEAM; i++) {
        uint256 tokenId = winnerTokenStart.add(i);
        uint256 tokenBalance = teamTokens.balanceOf(address(this), tokenId);
        if (tokenBalance == 0) continue;
        uint256 tokenValue = tokenBalance.mul(TOKEN_VALUE_BASE).div(1000);
        uint256 winnerTokenValue = tokenValue
            .mul(_winnerScore.sub(_loserScore))
            .mul(WIN_RATIO)
            .div(SCORE_RATIO_BASE);
        uint256 loserTokenValue = tokenValue.mul(LOSE_RATIO).div(SCORE_RATIO_BASE);
        uint256 winnerAmount = winnerTokenValue.add(tokenBalance.mul(BASE_RATE));
        uint256 loserAmount = loserTokenValue.add(tokenBalance.mul(BASE_RATE));
        globalTreasury += loserAmount;
        teamTreasury[_loserTeamIndex] += loserAmount;
        teamTreasury[_winnerTeamIndex] += winnerAmount;
        emit TeamTokenRedistributed(tokenId, _winnerTeamIndex, _loserTeamIndex, winnerAmount, loserAmount);
    }
}

function _calculateTotalScore(uint256[] memory _teamScores)
    private
    returns (uint256, uint256)
{
    uint256 scoreA = 0;
    uint256 scoreB = 0;
    for (uint256 i = 0; i < 1230; i++) {
        GameResult storage gameResult = gameResults[i];
        if (gameResult.teamIndexA == 0) continue;
        if (gameResult.scoreA > gameResult.scoreB) {
            _teamScores[gameResult.teamIndexA] += 2;
        } else if (gameResult.scoreA < gameResult.scoreB) {
            _teamScores[gameResult.teamIndexB] += 2;
        } else {
            _teamScores[gameResult.teamIndexA] += 1;
            _teamScores[gameResult.teamIndexB] += 1;
        }
        scoreA += gameResult.scoreA;
        scoreB += gameResult.scoreB;
    }
    return (scoreA, scoreB);
}

function getTeamToken(uint256 _teamIndex) public pure returns (uint256) {
    return _teamIndex.mul(TOKENS_PER_TEAM);
}

function getTeamTreasury(uint256 _teamIndex) public view returns (uint256) {
    return teamTreasury[_teamIndex];
}

function withdrawReserve(uint256 _amount) external onlyOwner {
    require(_amount <= reserveBalance, "Not enough reserve balance.");
    reserveBalance -= _amount;
    payable(owner()).transfer(_amount);
}

function withdrawTeamTreasury(uint256 _teamIndex, uint256 _amount) external onlyOwner {
    require(_amount <= teamTreasury[_teamIndex], "Not enough team treasury balance.");
    teamTreasury[_teamIndex] -= _amount;
    payable(owner()).transfer(_amount);
}

function withdrawGlobalTreasury(uint256 _amount) external onlyOwner {
    require(_amount <= globalTreasury, "Not enough global treasury balance.");
    globalTreasury -= _amount;
    payable(owner()).transfer(_amount);
}
