// src/App.js
import React, { useState, useEffect } from 'react';
import PuckCityContract from './contracts/PuckCity';
import './App.css';

// Import team crests
import ANA from './assets/ANA.png';
// ... (import all 32 team crests)

const teamCrests = {
  ANA: ANA,
  // ... (all 32 team crests)
};

function App() {
  const [account, setAccount] = useState('');
  const [teams, setTeams] = useState([]);
  const [selectedTeam, setSelectedTeam] = useState('');
  const [teamTokens, setTeamTokens] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    loadTeams();
  }, []);

  async function loadTeams() {
    setIsLoading(true);
    setError('');
    try {
      // Load teams from the contract
      // Replace with the actual implementation
      setTeams([
        { abbreviation: 'ANA', name: 'Anaheim Ducks' },
        // ... (all 32 teams)
      ]);
    } catch (err) {
      setError('Failed to load teams');
    } finally {
      setIsLoading(false);
    }
  }

  async function connectWallet() {
    setIsLoading(true);
    setError('');
    try {
      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
      setAccount(accounts[0]);
    } catch (err) {
      setError('Failed to connect wallet');
    } finally {
      setIsLoading(false);
    }
  }

  function onSelectTeam(e) {
    setSelectedTeam(e.target.value);
  }

  function onTokenAmountChange(e) {
    setTeamTokens(parseInt(e.target.value));
  }

  async function purchaseTokens(e) {
    e.preventDefault();
    setIsLoading(true);
    setError('');
    try {
      // Purchase team tokens
      // Replace with the actual implementation
    } catch (err) {
      setError('Failed to purchase tokens');
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="app">
      <h1>Puck City</h1>
      {error && <div className="error">{error}</div>}
      <button onClick={connectWallet}>Connect Wallet</button>
      {isLoading && <div className="loading">Loading...</div>}
      {account && (
        <div>
          <h2>Account: {account}</h2>
          <form onSubmit={purchaseTokens}>
            <label
            htmlFor="team">Select Team:</label>
            <select id="team" value={selectedTeam} onChange={onSelectTeam}>
              {teams.map((team) => (
                <option key={team.abbreviation} value={team.abbreviation}>{team.name}</option>
              ))}
            </select>
            <label htmlFor="tokens">Tokens:</label>
            <input id="tokens" type="number" value={teamTokens} onChange={onTokenAmountChange} />
            <button type="submit">Purchase Tokens</button>
          </form>
          <h2>Teams</h2>
          <div className="teams-container">
            {teams.map((team) => (
              <div className="tooltip" key={team.abbreviation}>
                <div className="team-card">
                  <img src={teamCrests[team.abbreviation]} alt={`${team.name} crest`} />
                  <h3>{team.name}</h3>
                  <p>Token Price: ...</p>
                  <p>Team Treasury: ...</p>
                </div>
                <div className="tooltip-text">
                  <p>Win Rate: ...%</p>
                  <p>Games Played: ...</p>
                  <p>Games Remaining: ...</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
      <button onClick={() => window.open('https://discord.gg/YOUR_INVITE_CODE', '_blank')}>Join Discord</button>
    </div>
  );
}

export default App;
