// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 正确的导入语句
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";  
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStudyToken is IERC20 {
    function mint(address _to, uint256 _amount, string calldata _reason) external;
}

/**
 * @title AchievementReward
 * @dev 成就奖励合约：依据学习成就发放 STU 奖励，可选择使用 StudyToken 的铸造或金库代币转账两种模式
 */
contract AchievementReward is Ownable, Pausable {
    // ===== 配置与引用 =====
    IStudyToken public studyToken;          // StudyToken 合约引用
    bool public useMint = false;            // 是否使用合约铸造奖励（需将本合约设为 StudyToken 管理员）
    uint256 public mintLimit = 1000 * 10**18; // 与 StudyToken 的单次铸造上限保持一致

    // 评审角色（仅评审或所有者可审核）
    mapping(address => bool) public reviewers;

    // ===== 成就类型定义 =====
    struct AchievementType {
        string name;            // 类型名称，例如：课程完成/优秀表现
        uint256 baseReward;     // 基础奖励（以最小单位计，如 18 位精度）
        uint256 multiplier;     // 乘数，用于 score 奖励：reward = base + score * multiplier
        bool active;            // 是否启用
    }

    AchievementType[] public types; // 类型列表

    // ===== 成就记录 =====
    enum Status { Pending, Approved, Rejected, Rewarded }

    struct Achievement {
        address user;
        uint256 typeId;
        uint256 score;         // 自定义评分或权重（由提交方定义）
        string reason;         // 说明（如学习成就描述）
        string evidenceURI;    // 证明材料链接（可选）
        uint256 rewardAmount;  // 计算后的奖励数量（最小单位）
        Status status;
        uint256 timestamp;
    }

    Achievement[] public achievements;

    // ===== 事件 =====
    event StudyTokenSet(address indexed token);
    event ReviewerSet(address indexed reviewer, bool enabled);
    event TypeAdded(uint256 indexed typeId, string name, uint256 baseReward, uint256 multiplier);
    event TypeUpdated(uint256 indexed typeId, string name, uint256 baseReward, uint256 multiplier, bool active);
    event AchievementSubmitted(uint256 indexed id, address indexed user, uint256 typeId, uint256 score, uint256 rewardAmount);
    event AchievementApproved(uint256 indexed id, address indexed reviewer);
    event AchievementRejected(uint256 indexed id, address indexed reviewer);
    event RewardDistributed(uint256 indexed id, address indexed to, uint256 amount, bool byMint);
    event ModeSwitched(bool useMintMode);
    event MintLimitUpdated(uint256 newLimit);

    // ===== 修饰符 =====
    modifier onlyReviewerOrOwner() {
        require(reviewers[msg.sender] || msg.sender == owner(), "AchievementReward: not reviewer or owner");
        _;
    }

    // ===== 构造函数 =====
    constructor(address _studyToken) Ownable(msg.sender) {
        require(_studyToken != address(0), "AchievementReward: invalid token address");
        studyToken = IStudyToken(_studyToken);
        emit StudyTokenSet(_studyToken);
    }

    // ===== 基础管理 =====
    function setStudyToken(address _studyToken) external onlyOwner {
        require(_studyToken != address(0), "AchievementReward: invalid token address");
        studyToken = IStudyToken(_studyToken);
        emit StudyTokenSet(_studyToken);
    }

    function setReviewer(address _reviewer, bool _enabled) external onlyOwner {
        require(_reviewer != address(0), "AchievementReward: invalid reviewer");
        reviewers[_reviewer] = _enabled;
        emit ReviewerSet(_reviewer, _enabled);
    }

    function setUseMint(bool _useMint) external onlyOwner {
        useMint = _useMint;
        emit ModeSwitched(_useMint);
    }

    function setMintLimit(uint256 _limit) external onlyOwner {
        require(_limit > 0, "AchievementReward: invalid limit");
        mintLimit = _limit;
        emit MintLimitUpdated(_limit);
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    // ===== 类型管理 =====
    function addAchievementType(string calldata name, uint256 baseReward, uint256 multiplier) external onlyOwner returns (uint256) {
        require(bytes(name).length > 0, "AchievementReward: empty name");
        AchievementType memory t = AchievementType({
            name: name,
            baseReward: baseReward,
            multiplier: multiplier,
            active: true
        });
        types.push(t);
        uint256 newId = types.length - 1;
        emit TypeAdded(newId, name, baseReward, multiplier);
        return newId;
    }

    function updateAchievementType(uint256 typeId, string calldata name, uint256 baseReward, uint256 multiplier, bool active) external onlyOwner {
        require(typeId < types.length, "AchievementReward: invalid typeId");
        require(bytes(name).length > 0, "AchievementReward: empty name");
        AchievementType storage t = types[typeId];
        t.name = name;
        t.baseReward = baseReward;
        t.multiplier = multiplier;
        t.active = active;
        emit TypeUpdated(typeId, name, baseReward, multiplier, active);
    }

    // ===== 成就提交与审核 =====
    function submitAchievement(
        uint256 typeId,
        uint256 score,
        string calldata reason,
        string calldata evidenceURI
    ) external whenNotPaused returns (uint256) {
        require(typeId < types.length, "AchievementReward: invalid typeId");
        AchievementType memory t = types[typeId];
        require(t.active, "AchievementReward: type inactive");

        uint256 rewardAmount = t.baseReward + score * t.multiplier;
        Achievement memory a = Achievement({
            user: msg.sender,
            typeId: typeId,
            score: score,
            reason: reason,
            evidenceURI: evidenceURI,
            rewardAmount: rewardAmount,
            status: Status.Pending,
            timestamp: block.timestamp
        });
        achievements.push(a);
        uint256 id = achievements.length - 1;
        emit AchievementSubmitted(id, msg.sender, typeId, score, rewardAmount);
        return id;
    }

    function approveAchievement(uint256 id) external whenNotPaused onlyReviewerOrOwner {
        require(id < achievements.length, "AchievementReward: invalid id");
        Achievement storage a = achievements[id];
        require(a.status == Status.Pending, "AchievementReward: not pending");
        a.status = Status.Approved;
        emit AchievementApproved(id, msg.sender);
        _distributeReward(id);
    }

    function rejectAchievement(uint256 id) external whenNotPaused onlyReviewerOrOwner {
        require(id < achievements.length, "AchievementReward: invalid id");
        Achievement storage a = achievements[id];
        require(a.status == Status.Pending, "AchievementReward: not pending");
        a.status = Status.Rejected;
        emit AchievementRejected(id, msg.sender);
    }

    // ===== 奖励发放 =====
    function _distributeReward(uint256 id) internal {
        Achievement storage a = achievements[id];
        require(a.status == Status.Approved, "AchievementReward: not approved");
        require(a.rewardAmount > 0, "AchievementReward: zero reward");

        if (useMint) {
            _safeMintInChunks(a.user, a.rewardAmount, a.reason);
        } else {
            require(studyToken.balanceOf(address(this)) >= a.rewardAmount, "AchievementReward: insufficient vault balance");
            require(studyToken.transfer(a.user, a.rewardAmount), "AchievementReward: transfer failed");
        }

        a.status = Status.Rewarded;
        emit RewardDistributed(id, a.user, a.rewardAmount, useMint);
    }

    function _safeMintInChunks(address to, uint256 amount, string memory reason) internal {
        uint256 remaining = amount;
        while (remaining > 0) {
            uint256 chunk = remaining > mintLimit ? mintLimit : remaining;
            studyToken.mint(to, chunk, reason);
            remaining -= chunk;
        }
    }

    // ===== 查询辅助 =====
    function getTypesCount() external view returns (uint256) { return types.length; }
    function getAchievementsCount() external view returns (uint256) { return achievements.length; }

    function getAchievementType(uint256 typeId) external view returns (
        string memory name,
        uint256 baseReward,
        uint256 multiplier,
        bool active
    ) {
        require(typeId < types.length, "AchievementReward: invalid typeId");
        AchievementType memory t = types[typeId];
        return (t.name, t.baseReward, t.multiplier, t.active);
    }

    function getAchievement(uint256 id) external view returns (
        address user,
        uint256 typeId,
        uint256 score,
        string memory reason,
        string memory evidenceURI,
        uint256 rewardAmount,
        Status status,
        uint256 timestamp
    ) {
        require(id < achievements.length, "AchievementReward: invalid id");
        Achievement memory a = achievements[id];
        return (a.user, a.typeId, a.score, a.reason, a.evidenceURI, a.rewardAmount, a.status, a.timestamp);
    }

    // ===== 金库维护 =====
    function vaultBalance() external view returns (uint256) {
        return studyToken.balanceOf(address(this));
    }

    function recoverTokens(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "AchievementReward: invalid recipient");
        require(IERC20(token).transfer(to, amount), "AchievementReward: recover failed");
    }
}