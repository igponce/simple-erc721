// SPDX-License-Identifier: MIT

// ERC721 sample
// Just the _minimal_ functionality for an Non-fungible-token
// See https://eips.ethereum.org/EIPS/eip-721 for full spec

pragma solidity >=0.8.4 ;

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

    // Token name and symbol
    string private _name;
    string private _symbol;

    // Maps token ids to owners
    // _tokenowner[tokenId] -> owner address
    mapping(uint256 => address) private _tokenowner;

    // Maps addresses to token count
    // _tokencount[address] -> #tokens owned by address
    mapping(address => uint256) private _tokencount;

    // Authorizations for tokens (1 address for each token)
    // _authorized[token] = address authorized to manipulate this token   
    mapping(uint256 => address) private _autorized;   

    // Like ERC20 authorizations.
    // Operator address authorized to work with NFTs from this wallet.
    // _authorizedop[wallet] = operator
    mapping(address => address) private _authorizedoperator;

    // Events

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // Mints an NFT if does not exist
    function _mint(uint256 _id) private {
        // check _id does not exit.. yet
        require(_tokenowner[_id] != address(0)); // Zero address verboten
        _tokenowner[_id] = tx.origin;
        _tokencount[tx.origin]++;
    }

    // Count all NFT assigned to an owner
    // _owner must != zero address
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0x0));
        return _tokencount[_owner];
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
        } else {
           _authorizedoperator[msg.sender] = address(0);
        }
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenid) external view returns (address) {

       return address(0); // not implemented

    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
           return _authorizedoperator[_owner] == _operator;
    }

    // clear all aprovals etc after transfer
    function _clearAuth(uint256 _token) private {
        
    }
    
}
