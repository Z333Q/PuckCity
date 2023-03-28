// PuckCityV6 contract address
const CONTRACT_ADDRESS = "<your-contract-address>";

// Team tokens
const CITY_TOKENS = [
  { name: "Anaheim", image: "anaheim.png" },
  { name: "Arizona", image: "arizona.png" },
  { name: "Boston", image: "boston.png" },
  { name: "Buffalo", image: "buffalo.png" },
  { name: "Calgary", image: "calgary.png" },
  { name: "Carolina", image: "carolina.png" },
  { name: "Chicago", image: "chicago.png" },
  { name: "Colorado", image: "colorado.png" },
  { name: "Columbus", image: "columbus.png" },
  { name: "Dallas", image: "dallas.png" },
  { name: "Detroit", image: "detroit.png" },
  { name: "Edmonton", image: "edmonton.png" },
  { name: "Florida", image: "florida.png" },
  { name: "Los Angeles", image: "los-angeles.png" },
  { name: "Minnesota", image: "minnesota.png" },
  { name: "Montreal", image: "montreal.png" },
  { name: "Nashville", image: "nashville.png" },
  { name: "New Jersey", image: "new-jersey.png" },
  { name: "New York Islanders", image: "new-york-islanders.png" },
  { name: "New York Rangers", image: "new-york-rangers.png" },
  { name: "Ottawa", image: "ottawa.png" },
  { name: "Philadelphia", image: "philadelphia.png" },
  { name: "Pittsburgh", image: "pittsburgh.png" },
  { name: "San Jose", image: "san-jose.png" },
  { name: "St. Louis", image: "st-louis.png" },
  { name: "Tampa Bay", image: "tampa-bay.png" },
  { name: "Toronto", image: "toronto.png" },
  { name: "Vancouver", image: "vancouver.png" },
  { name: "Vegas", image: "vegas.png" },
  { name: "Washington", image: "washington.png" },
  { name: "Winnipeg", image: "winnipeg.png" },
];

// Load Web3
let web3;

if (window.ethereum) {
  web3 = new Web3(window.ethereum);
} else if (window.web3) {
  web3 = new Web3(window.web3.currentProvider);
} else {
  console.error("No Web3 provider detected");
}

// Load contract
async function loadContract() {
  const response = await fetch(`assets/PuckCityV6.json`);
  const data = await response.json();
  const networkId = await web3.eth.net.getId();
  const contract = new web3.eth.Contract(data.abi, CONTRACT_ADDRESS);
  return contract;
}

// Load account
async function loadAccount() {
  const accounts = await web3.eth.getAccounts();
  return accounts[0];
}

// Get city token ID
async function getCityTokenId(cityName) {
  const response = await fetch(`assets/cities.json`);
  const data = await response.json();
  const city = data.cities.find((city) => city.name === cityName);
  return city ? city.id : null;
}

// Display city token balances
async function displayCityTokenBalances() {
  const contract = await loadContract();
  const account = await loadAccount();
  const cityTokenBalances = await Promise.all(
    CITIES.map(async (city) => {
      const balance = await contract.methods.balanceOf(account, await getCityTokenId(city)).call();
      return { name: city, image: `${city.toLowerCase()}.png`, balance: balance };
    })
  );
  const totalStaked = await contract.methods.totalStaked().call();
  const stakedBalances = await Promise.all(
    CITIES.map(async (city) => {
      const stakedBalance = await contract.methods.getUserStakedBalance(account, city).call();
      const percentage = totalStaked == 0 ? 0 : stakedBalance * 100 / totalStaked;
      return { name: city, image: `${city.toLowerCase()}.png`, balance: stakedBalance, percentage: percentage };
    })
  );

  // Display city token balances
  const cityTokenList = document.getElementById("cityTokenList");
  cityTokenList.innerHTML = "";
  cityTokenBalances.forEach((cityTokenBalance) => {
    const cityTokenItem = document.createElement("li");
    cityTokenItem.classList.add("list-group-item");
    const cityTokenImage = document.createElement("img");
    cityTokenImage.src = `assets/${cityTokenBalance.image}`;
    cityTokenImage.classList.add("city-token-image");
    const cityTokenName = document.createElement("span");
    cityTokenName.textContent = cityTokenBalance.name;
    cityTokenName.classList.add("city-token-name");
    const cityTokenBalanceElement = document.createElement("span");
    cityTokenBalanceElement.textContent = `${cityTokenBalance.balance}`;
    const cityTokenBalanceIcon = document.createElement("i");
    cityTokenBalanceIcon.classList.add("fas", "fa-hockey-puck");
    cityTokenBalanceElement.appendChild(cityTokenBalanceIcon);
    cityTokenItem.appendChild(cityTokenImage);
    cityTokenItem.appendChild(cityTokenName);
    cityTokenItem.appendChild(cityTokenBalanceElement);
    cityTokenList.appendChild(cityTokenItem);
  });

  // Display staked city token balances
  const stakedCityTokenList = document.getElementById("stakedCityTokenList");
  stakedCityTokenList.innerHTML = "";
  stakedBalances.forEach((stakedBalance) => {
    const stakedCityTokenItem = document.createElement("li");
    stakedCityTokenItem.classList.add("list-group-item");
    const stakedCityTokenImage = document.createElement("img");
    stakedCityTokenImage.src = `assets/${stakedBalance.image}`;
    stakedCityTokenImage.classList.add("city-token-image");
    const stakedCityTokenName = document.createElement("span");
    stakedCityTokenName.textContent = stakedBalance.name;
    stakedCityTokenName.classList.add("city-token-name");
const stakedCityTokenBalance = document.createElement("span");
    stakedCityTokenBalance.textContent = `${stakedBalance.balance.toFixed(2)} ${stakedBalance.symbol}`;
    stakedCityTokenItem.appendChild(stakedCityTokenImage);
    stakedCityTokenItem.appendChild(stakedCityTokenName);
    stakedCityTokenItem.appendChild(stakedCityTokenBalance);
    const stakedCityTokenProgressBar = document.createElement("div");
    stakedCityTokenProgressBar.classList.add("progress");
    const stakedCityTokenProgressBarFill = document.createElement("div");
    stakedCityTokenProgressBarFill.classList.add("progress-bar");
    stakedCityTokenProgressBarFill.classList.add(`bg-${stakedBalance.color}`);
    stakedCityTokenProgressBarFill.setAttribute("role", "progressbar");
    stakedCityTokenProgressBarFill.style.width = `${stakedBalance.percentage}%`;
    stakedCityTokenProgressBarFill.setAttribute("aria-valuenow", `${stakedBalance.percentage}`);
    stakedCityTokenProgressBarFill.setAttribute("aria-valuemin", "0");
    stakedCityTokenProgressBarFill.setAttribute("aria-valuemax", "100");
    stakedCityTokenProgressBarFill.textContent = `${stakedBalance.percentage.toFixed(2)}%`;
    stakedCityTokenProgressBar.appendChild(stakedCityTokenProgressBarFill);
    stakedCityTokenItem.appendChild(stakedCityTokenProgressBar);
    stakedCityTokenList.appendChild(stakedCityTokenItem);
  });
}

// Stake city tokens
async function stakeCityTokens(event) {
  event.preventDefault();
  const city = document.getElementById("stakeCitySelect").value;
  const amount = document.getElementById("stakeAmount").value;

  if (!city) {
    showErrorMessage("Please select a city");
    return;
  }

  if (amount <= 0) {
    showErrorMessage("Please enter a valid amount to stake");
    return;
  }

  const contract = await loadContract();
  const balance = await contract.methods.getCityTokenBalance(await loadAccount(), city).call();
  if (balance < amount) {
    showErrorMessage(`Insufficient ${city} tokens balance`);
    return;
  }

  try {
    await contract.methods.stakeCityTokens(city, web3.utils.toWei(amount)).send({
      from: await loadAccount(),
      gas: 100000,
    });
    showSuccessMessage(`Successfully staked ${amount} ${city} tokens`);
  } catch (error) {
    showErrorMessage(`Error staking ${city} tokens: ${error.message}`);
  }
  displayCityTokenBalances();
  displayStakedCityTokenBalances();
}

// Unstake city tokens
async function unstakeCityTokens(event) {
  event.preventDefault();
  const city = document.getElementById("unstakeCitySelect").value;
  const amount = document.getElementById("unstakeAmount").value;

  if (!city) {
    showErrorMessage("Please select a city");
    return;
  }

  if (amount <= 0) {
    showErrorMessage("Please enter a valid amount to unstake");
    return;
  }

  const contract = await loadContract();
  const balance = await contract.methods.getUserStakedBalance(await loadAccount(), city).call();
  if (balance < amount) {
    showErrorMessage(`Insufficient staked ${city} tokens balance`);
    return;
  }

  try {
    await contract.methods.unstakeCityTokens(city, web3.utils.toWei(amount)).send({
      from: await loadAccount(),
      gas: 100000,
    });
    showSuccessMessage(`Successfully unstaked ${amount} ${city} tokens`);
  } catch (error) {
    showErrorMessage(`Error unstaking ${city} tokens: ${error.message}`);
}

// Claim rewards
async function claimRewards() {
const city = document.getElementById("claimCitySelect").value;

if (!city) {
showErrorMessage("Please select a city");
return;
}

const contract = await loadContract();
const balance = await contract.methods.getUserStakedBalance(await loadAccount(), city).call();

if (balance <= 0) {
showErrorMessage(No staked balance for ${city});
return;
}

try {
await contract.methods.claimReward(city).send({
from: await loadAccount(),
gas: 100000,
});
showSuccessMessage(Successfully claimed reward for ${city});
} catch (error) {
showErrorMessage(Error claiming reward: ${error.message});
}
displayCityTokenBalances();
displayStakedCityTokenBalances();
}

// Event listeners
document.getElementById("connectButton").addEventListener("click", connectWallet);
document.getElementById("disconnectButton").addEventListener("click", disconnectWallet);
document.getElementById("stakeCityForm").addEventListener("submit", stakeCityTokens);
document.getElementById("unstakeCityForm").addEventListener("submit", unstakeCityTokens);
document.getElementById("claimCityForm").addEventListener("submit", claimRewards);

// Initial display of city token balances
displayCityTokenBalances();
displayStakedCityTokenBalances();


