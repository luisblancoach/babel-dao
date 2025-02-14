// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BabeToken is ERC20, Ownable, ReentrancyGuard {
    struct Nation {
    bool isActive;
    uint256 rewardPool;
    uint256 minLevelForMining;
    uint256 dailyMiningCap;
    uint256 lastReset;
    address steward; // AI Agent assigned to manage the DAO
    }

 struct Staker {
    uint256 amount;
    uint256 unlockTime;
    uint256 experienceLevel;
    uint256 rewardMultiplier;
    uint256 baseAPR;
    uint256 lastVoteBlock;
}

function stake(uint256 _amount) external {
    stakes[msg.sender] = Staker({
    amount: _amount,
    unlockTime: block.timestamp + 30 days,
    experienceLevel: 1,
    rewardMultiplier: 1,
    baseAPR: 10,
    lastVoteBlock: block.number
    });

    emit StakeCreated(msg.sender, _amount, block.timestamp);
    }
    function unstake() external {
    require(stakes[msg.sender].amount > 0, "No active stake");

    uint256 amount = stakes[msg.sender].amount;
    delete stakes[msg.sender]; // Reset the stake

    emit StakeWithdrawn(msg.sender, amount, block.timestamp);
    }
    
function calculateRewards(address _user) external view returns (uint256) {
    return stakes[_user].amount * stakes[_user].baseAPR / 100;
    }
}
    struct Proposal {
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
    }

    mapping(string => Nation) public nations;
    mapping(address => mapping(string => uint256)) public userMiningPower;
    mapping(address => uint256) public degenRiskLevel;
    mapping(address => uint256) public regenStabilityLevel;
    mapping(address => string) public currentNation;
    mapping(address => Staker) public stakers;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(address => bool) public verifiedUsers;

    uint256 public totalBurned;
    uint256 public proposalCount;
    uint256 public minStakeToVote = 100 * 10**18; // Minimum 100 $BABE to vote
    uint256 public minStakingDuration = 7 days; // Tokens must be staked at least 7 days before voting
    uint256 public globalMiningRate = 10 * 10**18; // 10 $BABE per block
    uint256 public maxSupply = 1_000_000_000 * 10**18; // 1B $BABE
    uint256 public totalMinted;

    event NationActivated(string nation);
    event TokensMined(address indexed user, string nation, uint256 amount, bool success);
    event TokensBurned(uint256 amount);
    event MiningUnlocked(string nation, uint256 minLevel);
    event RiskAdjusted(address indexed user, uint256 newRiskLevel);
    event StewardAssigned(string nation, address steward);
    event TokensStaked(address indexed user, uint256 amount, uint256 unlockTime, uint256 experienceLevel, uint256 rewardMultiplier, uint256 baseAPR);
    event TokensUnstaked(address indexed user, uint256 amount, uint256 profitLoss);

    event ProposalCreated(uint256 proposalId, string description, uint256 endTime);
    event VoteCast(address indexed voter, uint256 proposalId, bool support);
    event ProposalExecuted(uint256 proposalId, bool success);
    event UserVerified(address indexed user);
    
    constructor() ERC20("Babel Token", "BABE") {
    _mint(msg.sender, 10_000_000 * 10**18); // 10M $BABE to treasury for initial distribution
    }

    modifier onlyVerified() {
        require(verifiedUsers[msg.sender], "User not verified");
        _;
    }

    modifier validVotingPower() {
        require(stakers[msg.sender].amount >= minStakeToVote, "Insufficient stake to vote");
        require(block.timestamp >= stakers[msg.sender].unlockTime - minStakingDuration, "Stake must be locked for minimum duration");
        _;
    }

    function verifyUser(address user) external onlyOwner {
        verifiedUsers[user] = true;
        emit UserVerified(user);
    }

    function createProposal(string memory description, uint256 duration) external onlyVerified validVotingPower {
        require(duration >= 3 days, "Minimum proposal duration is 3 days");
        uint256 proposalId = proposalCount++;
        proposals[proposalId] = Proposal(description, 0, 0, block.timestamp + duration, false);
        emit ProposalCreated(proposalId, description, block.timestamp + duration);
    }

    function voteOnProposal(uint256 proposalId, bool support) external onlyVerified validVotingPower {
        require(block.timestamp < proposals[proposalId].endTime, "Voting period has ended");
        require(!hasVoted[msg.sender][proposalId], "Already voted");
        require(stakers[msg.sender].lastVoteBlock < proposals[proposalId].endTime, "Tokens must be staked before proposal started");
        
        uint256 votingPower = stakers[msg.sender].amount / 10**18; // 1 vote per token staked
        if (support) {
            proposals[proposalId].votesFor += votingPower;
        } else {
            proposals[proposalId].votesAgainst += votingPower;
        }
        hasVoted[msg.sender][proposalId] = true;
        stakers[msg.sender].lastVoteBlock = block.number;
        emit VoteCast(msg.sender, proposalId, support);
    }
}
