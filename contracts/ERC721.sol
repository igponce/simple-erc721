// SPDX-License-Identifier: MIT

// ERC721 sample
// Just the _minimal_ functionality for an Non-fungible-token
// See https://eips.ethereum.org/EIPS/eip-721 for full spec

pragma solidity >=0.8.4 ;

import "../interfaces/IERC721TokenReceiver.sol";

contract SimpleERC721 {

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
    // ** there is no "unapprove()" method, tokens can have just
    // one approved address.
    mapping(uint256 => address) private _autorized;   

    // Like ERC20 authorizations.
    // Operator address authorized to work with NFTs from this wallet.
    // _authorizedop[wallet] = operator
    mapping(address => mapping(address => bool)) private _authorizedoperator;

    // Events

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenid);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenid);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // event Debug(address _addr, uint256 _value, string _str);

    constructor() {
        // mints two NFT with owner by the contract deployer
        // this must go elsewhere
        _mint(1, msg.sender, false);
        _mint(2, msg.sender, false);
    }

    // Mints an NFT if does not exist
    function _mint(uint256 _id, address _owner, bool _emitMSG) private {
        require(_owner != address(0), "Zero address owner"); // Cannot crate for Zero address;
        require(_tokenowner[_id] == address(0)); // If exists (has owner) cannot mint again
        _tokenowner[_id] = _owner;
        _tokencount[_owner]++;

        if (_emitMSG) {
            // This is called if we're not in the constructor
            emit Transfer(address(0), _owner, _id);
        }
    }

    // Count all NFT assigned to an owner
    // _owner must != zero address
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0x0));
        return _tokencount[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return _tokenowner[_tokenId];
    }
    
    function _doTransferFrom(address _from, address _to, uint256 _tokenid) private {
        require(msg.sender == _from || 
                _autorized[_tokenid] == msg.sender ||
                 _authorizedoperator[_from][msg.sender] == true );
        require(_tokenowner[_tokenid] == _from);
        require(_to != address(0));
        
        // Clear authorization first
        _clearAuth(_tokenid);

        _tokencount[_from] -= 1;
        _tokencount[_to] += 1;
        _tokenowner[_tokenid] = _to;
   }

    function safeTransferFrom(address _from, address _to, uint256 _tokenid, bytes memory _data) public virtual {

        // First transfer the token
        // then check onERC721Receiver,
        // and finally revert() OR emit Transfer event
        _doTransferFrom(_from,_to,_tokenid);

        bytes4 return_value;
        
        // if _to_address is a contract, try to call onERC721Received()
        
        if (isContract(_to)) {

           try ERC721TokenReceiver(_to).onERC721Received(
                msg.sender, 
                _from,
                _tokenid,
                _data) returns (bytes4 retval)
           {
               return_value = retval;

           } catch /*(bytes memory error) */ {
               /* revert("Va a ser que no");

               

               if (error.length == 0) {
                   // unimplemented by called contract
               
            */    revert("Receiver does not support ERC721Receiver interface");
              /* } else {
                   // reverted by called contract
                   revert("Contract reverted after calling onERC721Receiver");
               }
               */
           }

           // 0x150b7a02 == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)") )
           require(return_value == 0x150b7a02, "Transfer not accepted");

        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenid) external {
        safeTransferFrom(_from,_to,_tokenid,"");
    }

    function transferFrom(address _from, address _to, uint256 _tokenid) external  {
        _doTransferFrom(_from,_to,_tokenid);
        emit Transfer(_from, _to, _tokenid);
    }

    function approve(address _approved, uint256 _tokenid) external  {
        require(msg.sender == _tokenowner[_tokenid]);
        _autorized[_tokenid] = _approved;
        emit Approval(_tokenowner[_tokenid], _approved, _tokenid);
    }

    function setApprovalForAll(address _operator, bool _approved) external   {
        if (_operator != address(0)) {
            if (_approved) {
               _authorizedoperator[msg.sender][_operator] = _approved; // true
            } else {
                delete(_authorizedoperator[msg.sender][_operator]); // should be cheaper that setting to false?
            }
            emit ApprovalForAll(msg.sender, _operator, _approved);
        }
    }

    function getApproved(uint256 _tokenid) external view returns (address) {
       return _autorized[_tokenid];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _authorizedoperator[_owner][_operator];
    }

    // clear all aprovals etc after transfer
    function _clearAuth(uint256 _tokenid) private {
        _autorized[_tokenid] = address(0);
    }

    // ERC165 supportsInterface
    // Returns true if the contract supports the inteface.
    // Returns false it does not support it *or* interfaceID is 0xffffffff
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        if ((interfaceId == 0x01ffc9a7) // supportsInterface
            || (interfaceId == 0x80ac58cd) // erc721 - 'vanilla interface'
        ) {
            return true;
        }
        return false;
    }

    /*** From OpenZeppelin ***/
    function isContract(address account) public view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.
    uint256 size;
        assembly {
            size := extcodesize(account)
        }
    return size > 0;
    }
    
}
