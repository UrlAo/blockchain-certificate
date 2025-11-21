// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CertificateRegistry {
    address public admin;
    mapping(address => bool) public issuers;
    mapping(address => uint256) public nonces;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant CERT_TYPEHASH = keccak256("Certificate(bytes32 certHash,string studentId,string studentName,string degree,string ipfsCid,uint256 nonce)");
    
    struct Certificate {
        string studentId;
        string studentName;
        string degree;
        uint256 issueDate;
        bool isIssued;
        bool revoked;
        string revokeReason;
        uint256 revokeDate;
        string ipfsCid;
    }
    
    // 映射：证书哈希 => 证书信息
    mapping(bytes32 => Certificate) public certificates;
    mapping(bytes32 => bool) public batchRoots;
    
    // 事件：用于前端监听
    event CertificateIssued(bytes32 indexed certHash, string studentId, string studentName);
    event CertificateVerified(bytes32 indexed certHash, bool isValid);
    event CertificateRevoked(bytes32 indexed certHash, string reason);
    event IssuerAdded(address indexed account);
    event IssuerRemoved(address indexed account);
    event BatchRootIssued(bytes32 indexed root, string batchId);
    
    // 构造函数，部署者就是管理员
    constructor() {
        admin = msg.sender;
        issuers[admin] = true;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("CertificateRegistry")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    
    // 修饰器：只有管理员能调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyIssuer() {
        require(issuers[msg.sender], "Only issuer can call this function");
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
    ) external onlyIssuer {
        Certificate memory prev = certificates[_certHash];
        require(!(prev.isIssued && !prev.revoked), "Certificate already issued");
        
        certificates[_certHash] = Certificate({
            studentId: _studentId,
            studentName: _studentName,
            degree: _degree,
            issueDate: block.timestamp,
            isIssued: true,
            revoked: false,
            revokeReason: "",
            revokeDate: 0,
            ipfsCid: ""
        });
        
        emit CertificateIssued(_certHash, _studentId, _studentName);
    }

    function issueCertificateWithCid(
        bytes32 _certHash,
        string memory _studentId,
        string memory _studentName,
        string memory _degree,
        string memory _ipfsCid
    ) external onlyIssuer {
        Certificate memory prev = certificates[_certHash];
        require(!(prev.isIssued && !prev.revoked), "Certificate already issued");
        certificates[_certHash] = Certificate({
            studentId: _studentId,
            studentName: _studentName,
            degree: _degree,
            issueDate: block.timestamp,
            isIssued: true,
            revoked: false,
            revokeReason: "",
            revokeDate: 0,
            ipfsCid: _ipfsCid
        });
        emit CertificateIssued(_certHash, _studentId, _studentName);
    }

    function issueBatch(
        bytes32[] memory _hashes,
        string[] memory _studentIds,
        string[] memory _studentNames,
        string[] memory _degrees
    ) external onlyIssuer {
        require(
            _hashes.length == _studentIds.length &&
            _hashes.length == _studentNames.length &&
            _hashes.length == _degrees.length,
            "Array length mismatch"
        );
        for (uint256 i = 0; i < _hashes.length; i++) {
            bytes32 h = _hashes[i];
            Certificate memory prev = certificates[h];
            require(!(prev.isIssued && !prev.revoked), "Certificate already issued");
            certificates[h] = Certificate({
                studentId: _studentIds[i],
                studentName: _studentNames[i],
                degree: _degrees[i],
                issueDate: block.timestamp,
                isIssued: true,
                revoked: false,
                revokeReason: "",
                revokeDate: 0,
                ipfsCid: ""
            });
            emit CertificateIssued(h, _studentIds[i], _studentNames[i]);
        }
    }

    function issueBatchRoot(bytes32 _root, string memory _batchId) external onlyIssuer {
        require(!batchRoots[_root], "Root already issued");
        batchRoots[_root] = true;
        emit BatchRootIssued(_root, _batchId);
    }

    function verifyLeaf(bytes32 _root, bytes32 _leaf, bytes32[] calldata _proof) external view returns (bool) {
        bytes32 computed = _leaf;
        for (uint256 i = 0; i < _proof.length; i++) {
            bytes32 proofElement = _proof[i];
            if (computed <= proofElement) {
                computed = keccak256(abi.encodePacked(computed, proofElement));
            } else {
                computed = keccak256(abi.encodePacked(proofElement, computed));
            }
        }
        return computed == _root && batchRoots[_root];
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

    function getCertificate(bytes32 _certHash)
        external
        view
        returns (
            bool,
            string memory,
            string memory,
            string memory,
            uint256,
            bool,
            string memory,
            uint256,
            string memory
        )
    {
        Certificate memory cert = certificates[_certHash];
        return (
            cert.isIssued,
            cert.studentId,
            cert.studentName,
            cert.degree,
            cert.issueDate,
            cert.revoked,
            cert.revokeReason,
            cert.revokeDate,
            cert.ipfsCid
        );
    }

    function revokeCertificate(bytes32 _certHash, string memory _reason) external onlyAdmin {
        Certificate storage cert = certificates[_certHash];
        require(cert.isIssued, "Certificate not issued");
        require(!cert.revoked, "Certificate already revoked");
        cert.revoked = true;
        cert.revokeReason = _reason;
        cert.revokeDate = block.timestamp;
        emit CertificateRevoked(_certHash, _reason);
    }

    function issueWithSig(
        bytes32 _certHash,
        string memory _studentId,
        string memory _studentName,
        string memory _degree,
        string memory _ipfsCid,
        uint256 _nonce,
        bytes calldata _signature
    ) external {
        bytes32 structHash = keccak256(
            abi.encode(
                CERT_TYPEHASH,
                _certHash,
                keccak256(bytes(_studentId)),
                keccak256(bytes(_studentName)),
                keccak256(bytes(_degree)),
                keccak256(bytes(_ipfsCid)),
                _nonce
            )
        );
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));

        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "Invalid signature");
        require(issuers[signer], "Signer not issuer");
        require(_nonce == nonces[signer], "Invalid nonce");
        nonces[signer]++;

        Certificate memory prev = certificates[_certHash];
        require(!(prev.isIssued && !prev.revoked), "Certificate already issued");
        certificates[_certHash] = Certificate({
            studentId: _studentId,
            studentName: _studentName,
            degree: _degree,
            issueDate: block.timestamp,
            isIssued: true,
            revoked: false,
            revokeReason: "",
            revokeDate: 0,
            ipfsCid: _ipfsCid
        });
        emit CertificateIssued(_certHash, _studentId, _studentName);
    }

    function _splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "bad signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27) v += 27;
    }

    function addIssuer(address account) external onlyAdmin {
        issuers[account] = true;
        emit IssuerAdded(account);
    }

    function removeIssuer(address account) external onlyAdmin {
        issuers[account] = false;
        emit IssuerRemoved(account);
    }

    function isIssuer(address account) external view returns (bool) {
        return issuers[account];
    }
}