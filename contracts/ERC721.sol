// SPDX-License-Identifier: MIT

// ERC721 sample
// Just the _minimal_ functionality for an Non-fungible-token
// See https://eips.ethereum.org/EIPS/eip-721 for full spec

pragma solidity >=0.6.6;

// Stuff we need to implement
//
// Methods
//
// Events
//
// event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
//    Notifiesthe recipient that it received a specific token.
// event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);


contract myERC721 {

    mapping(uint256 => address) private _tokenowner;  // _tokenowner[tokenId] = address
    mapping(uint256 => uint256) private _autorized;   // _authorized[address] = tokenid  (many addresses -> 1 token)
    mapping(address => address) private _authorizedoperator; // Authorized operator ([address] -> operator

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // Count all NFT assigned to an owner
    // _owner must != zero address
    function balanceOf(address _owner) external view returns (uint256 _count) {
        require(_owner != address(0x00));
    /* To Do */
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenid, bytes memory _data) external payable {
        require(msg.sender == _tokenowner[_tokenid]);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenid) external payable {
        require(msg.sender == _tokenowner[_tokenid]);
    }

    function transferFrom(address _from, address _to, uint256 _tokenid) external payable {

    }

    function approve(address _approves, uint256 _tokenid) external payable {

    }

    function setAprovalForAll(address _operator, bool _approved) external payable {
        if (_approved) {
           _authorizedoperator[msg.sender] = _operator;
        else {
           _authorizedoperator[msg.sender] = address(0);
        }
        emit ApprovalForAll(msf.sender, _operator, _approved)
    }

    function getApproved(uint256 _tokenid) external payable{

    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
           return _authorizedoperator[_owner] == _operator
    }

    // clear all aprovals etc after transfer
    function _clearAuth(uint256 _token) private {
        
    }
    
}
