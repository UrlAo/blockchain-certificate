// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CertificateRegistry {
    address public admin;
    
    struct Certificate {
        string studentId;
        string studentName;
        string degree;
        uint256 issueDate;
        bool isIssued;
    }
    
    // 映射：证书哈希 => 证书信息
    mapping(bytes32 => Certificate) public certificates;
    
    // 事件：用于前端监听
    event CertificateIssued(bytes32 indexed certHash, string studentId, string studentName);
    event CertificateVerified(bytes32 indexed certHash, bool isValid);
    
    // 构造函数，部署者就是管理员
    constructor() {
        admin = msg.sender;
    }
    
    // 修饰器：只有管理员能调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    /**
     * @dev 发行证书
     * @param _certHash 证书文件的哈希值
     * @param _studentId 学生学号
     * @param _studentName 学生姓名
     * @param _degree 学位信息
     */
    function issueCertificate(
        bytes32 _certHash,
        string memory _studentId,
        string memory _studentName,
        string memory _degree
    ) external onlyAdmin {
        require(!certificates[_certHash].isIssued, "Certificate already issued");
        
        certificates[_certHash] = Certificate({
            studentId: _studentId,
            studentName: _studentName,
            degree: _degree,
            issueDate: block.timestamp,
            isIssued: true
        });
        
        emit CertificateIssued(_certHash, _studentId, _studentName);
    }
    
    /**
     * @dev 验证证书
     * @param _certHash 要验证的证书哈希
     * @return 是否有效，学生信息等
     */
    function verifyCertificate(bytes32 _certHash) 
        external 
        view 
        returns (bool, string memory, string memory, string memory, uint256) 
    {
        Certificate memory cert = certificates[_certHash];
        if (!cert.isIssued) {
            return (false, "", "", "", 0);
        }
        
        return (
            true,
            cert.studentId,
            cert.studentName,
            cert.degree,
            cert.issueDate
        );
    }
    
    /**
     * @dev 简单的证书验证，只返回是否有效
     */
    function simpleVerify(bytes32 _certHash) external view returns (bool) {
        return certificates[_certHash].isIssued;
    }
}