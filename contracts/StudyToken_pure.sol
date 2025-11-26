// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title StudyToken
 * @dev 学习教育代币合约
 * 支持铸造、转移、销毁等功能，带有暂停机制和管理员控制
 */
contract StudyToken is ERC20, Ownable, Pausable {

    // ====== 状态变量 ======

    uint256 public constant MINT_LIMIT = 1000000000000000000000; // 单次铸造限制
    address public admin; // 管理员地址
    address public deployer; // 部署者地址

    // ====== 事件定义 ======

    event Minted(address indexed to, uint256 amount, string reason);
    event Burned(address indexed from, uint256 amount, string reason);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event EmergencyMint(address indexed to, uint256 amount, string reason);

    // ====== 修饰符 ======

    modifier onlyAdmin() {
        require(msg.sender == admin, "StudyToken: Only admin can call this function");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "StudyToken: Invalid address");
        _;
    }

    modifier withinMintLimit(uint256 _amount) {
        require(_amount <= MINT_LIMIT, "StudyToken: Amount exceeds mint limit");
        _;
    }

    // ====== 构造函数 ======

    constructor() ERC20("StudyToken", "STU") Ownable(msg.sender) {
        uint256 initialAmount = 1000000000000000000000000;
        _mint(msg.sender, initialAmount);

        admin = msg.sender;
        deployer = msg.sender;

        emit Minted(msg.sender, initialAmount, "Initial supply");
    }

    // ====== 管理员函数 ======

    /**
     * @dev 铸造代币 (仅管理员)
     * @param _to 接收地址
     * @param _amount 铸造数量
     * @param _reason 铸造原因
     */
    function mint(address _to, uint256 _amount, string memory _reason) 
        external 
        onlyAdmin 
        validAddress(_to) 
        whenNotPaused
        withinMintLimit(_amount)
    {
        require(_amount > 0, "StudyToken: Amount must be greater than 0");

        _mint(_to, _amount);
        emit Minted(_to, _amount, _reason);
    }

    /**
     * @dev 紧急铸造 (仅管理员，无视暂停状态)
     * @param _to 接收地址
     * @param _amount 铸造数量
     * @param _reason 铸造原因
     */
    function emergencyMint(address _to, uint256 _amount, string memory _reason) 
        external 
        onlyAdmin 
        validAddress(_to)
    {
        require(_amount > 0, "StudyToken: Amount must be greater than 0");

        _mint(_to, _amount);
        emit EmergencyMint(_to, _amount, _reason);
    }

    /**
     * @dev 销毁代币 (任何用户)
     * @param _amount 销毁数量
     * @param _reason 销毁原因
     */
    function burn(uint256 _amount, string memory _reason) 
        external 
        whenNotPaused
    {
        require(_amount > 0, "StudyToken: Amount must be greater than 0");
        require(balanceOf(msg.sender) >= _amount, "StudyToken: Insufficient balance");

        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount, _reason);
    }

    /**
     * @dev 暂停合约 (仅管理员)
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
     * @dev 恢复合约 (仅管理员)
     */
    function unpause() external onlyAdmin {
        _unpause();
    }

    /**
     * @dev 紧急暂停 (仅部署者)
     */
    function emergencyPause() external {
        require(msg.sender == deployer, "StudyToken: Only deployer can call this function");
        _pause();
    }

    /**
     * @dev 更改管理员 (仅当前管理员)
     * @param _newAdmin 新管理员地址
     */
    function changeAdmin(address _newAdmin) 
        external 
        onlyAdmin 
        validAddress(_newAdmin)
    {
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminChanged(oldAdmin, _newAdmin);
    }

    /**
     * @dev 提取合约中的ETH (仅管理员)
     */
    function withdrawETH() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "StudyToken: No ETH to withdraw");

        (bool success, ) = admin.call{value: balance}("");
        require(success, "StudyToken: ETH withdrawal failed");
    }

    /**
     * @dev 批量转账 (管理员专用)
     * @param _recipients 接收地址数组
     * @param _amounts 对应金额数组
     */
    function batchTransfer(address[] memory _recipients, uint256[] memory _amounts) 
        external 
        onlyAdmin 
        whenNotPaused
    {
        require(_recipients.length == _amounts.length, "StudyToken: Arrays length mismatch");
        require(_recipients.length > 0, "StudyToken: Empty arrays");

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "StudyToken: Invalid recipient address");
            require(_amounts[i] > 0, "StudyToken: Invalid amount");

            _transfer(msg.sender, _recipients[i], _amounts[i]);
        }
    }

    // ====== 查询函数 ======

    /**
     * @dev 获取代币基本信息
     */
    function getTokenInfo() external view returns (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        uint256 mintLimit_,
        address admin_,
        bool paused_
    ) {
        return (
            name(),
            symbol(),
            decimals(),
            totalSupply(),
            MINT_LIMIT,
            admin,
            paused()
        );
    }

    /**
     * @dev 获取用户总财富 (包括余额和其他权益)
     * @param _user 用户地址
     */
    function getUserWealth(address _user) external view returns (uint256) {
        return balanceOf(_user);
    }

    /**
     * @dev 检查地址是否为管理员
     * @param _addr 待检查地址
     */
    function isAdmin(address _addr) external view returns (bool) {
        return _addr == admin;
    }

    /**
     * @dev 检查地址是否为部署者
     * @param _addr 待检查地址
     */
    function isDeployer(address _addr) external view returns (bool) {
        return _addr == deployer;
    }

    // ====== 重写的ERC20函数 ======

    /**
     * @dev 重写transfer函数，添加暂停检查
     */
    function transfer(address _to, uint256 _amount) 
        public 
        override 
        whenNotPaused
        returns (bool) 
    {
        return super.transfer(_to, _amount);
    }

    /**
     * @dev 重写transferFrom函数，添加暂停检查
     */
    function transferFrom(address _from, address _to, uint256 _amount) 
        public 
        override 
        whenNotPaused
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _amount);
    }

    // ====== 接收ETH ======

    /**
     * @dev 接收ETH，用于紧急情况
     */
    receive() external payable {}

    /**
     * @dev 回退函数
     */
    fallback() external payable {}
}