// SPDX-License-Identifier: MIT

// Test proxy
// This is a proxy test contract just to call
// other contract methods and make msg.sender != tx.origin
   
pragma solidity >=0.7.0;

interface iNFToken {
    function safeTransferFrom(address _from, address _to, uint256 _tokenid) external;
}


contract TestProxy {

   constructor(address tokenaddr) {
       token = tokenaddr;
   }
   
   address public immutable token;

   // enviando
   function proxy_safeTransferFrom(address sender,
                 address recipient,
                 uint256 id) external returns (bool) {

       iNFToken(token).safeTransferFrom(sender, recipient, id);
       return true;

   }

}
