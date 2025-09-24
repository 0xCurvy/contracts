import { AbstractContract, RevertError, expect, RevertUnsafeMathError } from './utils'
import * as utils from './utils'

import { MetaERC20Wrapper, CurvyAggregator } from 'src/gen/typechain'

import { BigNumber } from 'ethers'

// init test wallets from package.json mnemonic
import { ethers, web3 } from 'hardhat'

const { wallet: ownerWallet, provider: ownerProvider, signer: ownerSigner } = utils.createTestWallet(web3, 0)

const { wallet: receiverWallet, provider: receiverProvider, signer: receiverSigner } = utils.createTestWallet(web3, 2)

const { wallet: userWallet, provider: userProvider, signer: userSigner } = utils.createTestWallet(web3, 3)

const { wallet: operatorWallet, provider: operatorProvider, signer: operatorSigner } = utils.createTestWallet(web3, 4)

describe('CurvyAggregator', () => {
    // Initial token balance
    const INIT_BALANCE = 100
  
    // 4m gas limit when gas estimation is incorrect (internal txs)
    const txParam = { gasLimit: 4000000 }
  
    // Addresses
    const ZERO_ADDRESS: string = '0x0000000000000000000000000000000000000000' // Zero address
    const ETH_ADDRESS: string = '0x0000000000000000000000000000000000000001' // One address
    let receiverAddress: string // Address of receiver
    let userAddress: string // Address of user
    let tokenAddress: string
    let tokenID: BigNumber
    let wrapperAddress: string // Address of wrapper contract
    let curvyAggregatorAddress: string
    let ONE_ID = BigNumber.from(1)
  
    // Contracts
    let ownerMetaErc20WrapperContract: MetaERC20Wrapper
    let userMetaErc20WrapperContract: MetaERC20Wrapper

    let ownerCurvyAggregatorContract: CurvyAggregator
    let userCurvyAggregatorContract: CurvyAggregator

    // Provider
    const { provider } = ethers

    context('When CurvyAggregator contract is deployed', () => {
        before(async () => {
          receiverAddress = await receiverWallet.getAddress()
          userAddress = await userWallet.getAddress()
        })

        beforeEach(async () => {
            // Deploy MetaERC20Wrapper
            let abstractMetaErc20Wrapper = await AbstractContract.fromArtifactName('MetaERC20Wrapper')
            ownerMetaErc20WrapperContract = (await abstractMetaErc20Wrapper.deploy(ownerWallet)) as MetaERC20Wrapper
            userMetaErc20WrapperContract = (await ownerMetaErc20WrapperContract.connect(userSigner)) as MetaERC20Wrapper

            // Deploy CurvyAggregator
            let abstractCurvyAggregator = await AbstractContract.fromArtifactName('CurvyAggregator')
            ownerCurvyAggregatorContract = (await abstractCurvyAggregator.deploy(ownerMetaErc20WrapperContract.address)) as CurvyAggregator
            userCurvyAggregatorContract = (await ownerCurvyAggregatorContract.connect(userSigner)) as CurvyAggregator
      
            // Mint tokens to user
            tokenAddress = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
            tokenID = BigNumber.from(1)

            await userMetaErc20WrapperContract.functions.deposit(tokenAddress, userAddress, INIT_BALANCE);
      
            wrapperAddress = ownerMetaErc20WrapperContract.address
            curvyAggregatorAddress = ownerCurvyAggregatorContract.address
          })
        }
    )
});