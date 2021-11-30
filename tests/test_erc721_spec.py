#!/usr/env python
#
# Test ERC721 specification (minimal)

import pytest
import logging
import web3
from brownie import accounts, SimpleERC721 , testERC721Receiver, revertsERC721Receiver, exceptions, reverts, ZERO_ADDRESS

Zeroaddress = '0x0000000000000000000000000000000000000000'

@pytest.fixture
def token():
    """
    Deploy the contract and mint NFTs owned by accounts[0]
    """
    erc721 = accounts[0].deploy(SimpleERC721)
    return erc721

@pytest.fixture
def invalid_tokenid():
    import random
    return 100_000_000 + int(random.uniform(1,100_000_000))

def test_constructor():
    """
    Tests the constructor - accounts[0] deploys the contract.
    ERC721 spec states that it is possible _not_ to emit transfer
    events during contract creation.
    
    In our case, all minted tokens are owner by the deployer address.
    """

    deployer = accounts[0]

    token = deployer.deploy(SimpleERC721)

    assert token.balanceOf(deployer.address) > 0

def test_simple_transfers(token):
    """
    ERC721 transfers are tricky.
    There are 3 ways to transfer tokens:
      - A (human?) person does the transfer.
      - A contract (or address) transfer a token 
          - ... and it has permission to transfer just one token.
          - ... or it cat transfer any token this account has.
          
    """

    sender = accounts[0].address
    receiver = accounts[1].address
    tokenid = 1

    # Transfer to the zero address verboten
    with reverts():
       token.transferFrom(receiver, 
            ZERO_ADDRESS,
            tokenid, {'from': receiver})

    
    initial_balance = token.balanceOf(receiver)

    tx = token.transferFrom(sender, receiver, tokenid)
    assert token.balanceOf(receiver) == 1 + initial_balance

    transfer_event = dict(tx.events).get('Transfer')

    assert (transfer_event['_from'] == sender) & (
            transfer_event['_to'] == receiver ) & ( 
            transfer_event['_tokenid'] == tokenid)

    with reverts():
        # Only owner can transfer tokens
        token.transferFrom(receiver, sender, tokenid, {'from': sender})


def test_transfer_with_aproval(token):

    alice, bob = [ accounts[x].address for x in range(2) ]
    tokenid = 1

    token.approve(bob, tokenid, {'from': alice})

    # bob can transfer the token if he's authorized
    token.transferFrom(alice, bob, tokenid, {'from': bob})

    # after a transfer aprovals are cleared
    assert token.getApproved(tokenid) != bob
    assert token.getApproved(tokenid) == ZERO_ADDRESS

    # new owner can transfer without auth
    tx = token.transferFrom(bob, alice, tokenid, {'from': bob})

    # and there is a transfer event
    assert dict(tx.events).get('Transfer') != None


def test_transfer_by_operator(token):

    alice, bob = [ accounts[x].address for x in range(2) ]

    assert token.ownerOf(1) == alice

    # alice makes bob an operator for all
    tx = token.setApprovalForAll(bob, True, {'from': alice})

    # and there is an ApprovalForAll message
    assert dict(tx.events).get('ApprovalForAll') != None
    
    # bob can transfer more than one token grom alice
    for tokenid in range(1,3):
       tx = token.transferFrom(alice, bob, tokenid, {'from': bob})
       assert tx.events != None
       # after transfer aprovals are cleaed
       assert token.getApproved(tokenid) == ZERO_ADDRESS

def test_approve(token, invalid_tokenid):
    valid_tokenid = 1
    alice, bob = [x.address for x in accounts[0:2]]
    with reverts():
       # Fails with an invalid token
       tx = token.approve(bob, invalid_tokenid)
    
    tx = token.approve(bob, valid_tokenid)
    assert tx.events['Approval'] == {
        '_owner': alice,
        '_approved': bob,
        '_tokenid': valid_tokenid
    }

def test_ownerOf(token):
    # At start accounts[0] owns all tokens
    tokenid = 1
    owner = accounts[0].address
    others = [x.address for x in accounts[1:]]

    assert token.ownerOf(tokenid) == owner
    assert token.ownerOf(tokenid) not in others


def test_balanceOf(token):
    """
    ERC721 balanceOf(address) returns the number of tokens
    owned by this address. Reverts if address is the zero address.
    """
    # At start accounts[0] owns all tokens
    alice = accounts[0].address
    assert token.balanceOf(alice) > 0
    with reverts():
       tx = token.balanceOf(ZERO_ADDRESS)
    
def test_setApprovalForAll(token):
    """
    Enable or disable approval for a third party ("operator") to manage
    all of `msg.sender`'s assets.
    - Emits the ApprovalForAll event.
    - The contract MUST allow multiple operators per owner
    """

    # Test scenarios enable, then disable approvalForAll
    # for two operators.

    alice, bob, charlie = [x.address for x in accounts[0:3]]
    tokenid = 1

    # Does not revert with the zero address... but should not send any event.
    tx = token.setApprovalForAll(ZERO_ADDRESS, True)
    assert dict(tx.events).get('ApprovalForAll') == None

    # Set several operators
    token.setApprovalForAll(bob, True)
    token.setApprovalForAll(charlie, True)

    token.transferFrom(alice,charlie, tokenid, {'from': bob})
    token.transferFrom(alice,charlie, tokenid +1 , {'from': charlie})

    # Set several operators
    token.setApprovalForAll(bob, False)

    assert token.ownerOf(1) == charlie


def test_clearApprovalsAfterTransfer(token):

   alice, bob, charlie, operator = [accounts[x].address for x in range(4)]
   tokenid = 1

   # Transferring a token will clear approval for this token
   # Transfer from an operator, clears approval
   token.approve(operator, tokenid)
   assert token.getApproved(tokenid) == operator
   token.transferFrom(alice,bob,tokenid, {'from': operator})
   assert token.getApproved(tokenid) == ZERO_ADDRESS

   # Transfer directly crears approval
   token.approve(operator, tokenid, {'from': bob})
   token.transferFrom(bob,alice, tokenid, {'from': bob})
   assert token.getApproved(tokenid) == ZERO_ADDRESS
   
   # Transfer does not changhe setApprovalForAll

   # Transferring with allowForAll also changes aproval
   # Alice appoves bob for a token, but transfers using an operator.
   # aproval for the token is cleared, but the operator can still
   # transfer tokens from alice account
   token.approve(bob, tokenid)
   token.setApprovalForAll(operator, True, {'from': alice})
   token.transferFrom(alice, charlie, tokenid)

   assert token.getApproved(tokenid, {'from': alice}) != bob
   assert token.isApprovedForAll(alice,bob) == False

   token.transferFrom(charlie, alice, tokenid, {'from': charlie}) # return the token to alice

   # Transfer with safeTransferFrom changes aproval for the token
   # but not for the operator
   token.approve(bob, tokenid)
   token.setApprovalForAll(operator, True, {'from': alice})
   token.safeTransferFrom(alice, charlie, tokenid, {'from': bob})
   assert token.getApproved(tokenid) == ZERO_ADDRESS

    
def test_safeTransferFrom(token):
    """
    Tests for safeTransferFrom
    We use dummy contracts that always accept, reject, or revert
    the transaction to check the contract return values.
    """

    alice, bob, charlie = [ x.address for x in accounts[0:3]]

    alwaysOK = accounts[0].deploy(testERC721Receiver, True)
    alwaysKO = accounts[0].deploy(testERC721Receiver, False)
    alwaysReverts = accounts[0].deploy(revertsERC721Receiver)

    # Setup authorized operators for all

    for operator in [token, alice, bob]:
       token.setApprovalForAll(operator, True, {'from': alice})

    # This is an *opinionated* case:
    # If we have a contract (code size > 0),
    # we throw if the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    # When the contract does not implement that interface,
    # we can throw an error and comply with the standard.

    with reverts():
       tx = token.safeTransferFrom(alice, token, 1, {'from': alice} )
       #assert ee.revert_msg == "Receiver does not support ERC721Receiver interface"

    with reverts():
       # Contract that always reverts when called
       tx = token.safeTransferFrom(alice, alwaysReverts, 1)

    with reverts():
       # Contract that does not accept the transfer
       tx = token.safeTransferFrom(alice, alwaysKO, 1)

    # Now send it with some data attached
    with reverts():
       tx = token.safeTransferFrom(alice, alwaysReverts, 1, b"hello")

    # Finally, send the token to a simple address
    tx = token.safeTransferFrom(alice, bob, 1, b"Transfer to a wallet, not a contract")
    
def test_supportsInterface(token):

    testcases = [ 
        # interfaceId, return_value, interface_name
        ["0x00000000", False, "unimplemented interface"],
        ["0x01ffc9a7", True, "erc165 - supportsInterace"],
        ["0x80ac58cd", True, "erc721 interface"],
        ["0xffffffff", False, "erc165 - must return false"]
    ]

    for interface, expected, name in testcases:
        assert token.supportsInterface(interface) == expected, name


def test_isContract(token):
    assert token.isContract(token.address)
    assert not token.isContract(accounts[0].address)

def test_boomerangTransferReverts(token):
    """ Transfer from owner to owner MUST fail """
    alice = accounts[0].address
    tokenid = 1
    with reverts():
        token.transferFrom(alice, alice, tokenid, {'from': alice})
        