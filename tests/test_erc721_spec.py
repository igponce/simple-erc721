#!/usr/env python
#
# Test ERC721 specification (minimal)

import pytest
import logging
import web3
from brownie import accounts, SimpleERC721 , exceptions, reverts

@pytest.fixture
def token():
    """
    Deploy the contract and mint NFTs owned by accounts[0]
    """
    erc721 = accounts[0].deploy(SimpleERC721)
    return erc721


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
            '0x0000000000000000000000000000000000000000',
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

    # after a transfer aprovales are cleared
    assert token.getApproved(tokenid) != bob
    assert token.getApproved(tokenid) == '0x0000000000000000000000000000000000000000'

    # new owner can transfer without auth
    tx = token.transferFrom(bob, alice, tokenid, {'from': bob})

    # and there is a transfer event
    assert dict(tx.events).get('Transfer') != None


def test_transfer_by_operator(token):

    alice, bob = [ accounts[x].address for x in range(2) ]

    assert token.ownerOf(1) == alice #'0x0000000000000000000000000000000000000000'

    # alice makes bob an operator for all
    tx = token.setAprovalForAll(bob, True, {'from': alice})

    # and there is an ApprovalForAll message
    assert dict(tx.events).get('ApprovalForAll') != None
    
    # bob can transfer more than one token grom alice
    for tokenid in range(1,3):
       tx = token.transferFrom(alice, bob, tokenid, {'from': bob})
       assert tx.events != None

############### Unimplemented stuff ###################

def test_safeTransferFrom(toke):
    assert False
    
def test_aprove(token):
    assert False
    
def test_ownerOf(token):
    assert False
    
def test_setApprovalForAll(token):
    assert False
    
def test_unsetApprovalForAll(token):
    assert False
    
def test_clearApprovalsAfterTransfer(token):
    assert False
    
def test_supportsInterface(token):
    assert False
