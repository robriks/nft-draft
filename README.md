NFT Marketplace & Escrow Contract for Classical Musicians
by robriks github.com/robriks/consensys-academy-final-project
hornosexual.eth (0x65b54A4646369D8ad83CB58A5a6b39F22fcd8cEe)
# FEEL FREE TO SKIP TO TL;DR!

Writeup:

My inspiration:
As a hornist with the National Symphony Orchestra in Washington, DC, I have intimate familiarity with the inefficiencies of the global French Horn marketplace under legacy systems. (Note: these inefficiencies also permeate the classical music industry at large, however I have chosen to focus my efforts on the global horn market as this is my area of expertise. Future endeavors may expand this scope to other instrument markets.)

The problem:
These inefficiencies have grown to an unconscionable level, where rent-takers and middlemen abuse their positions in the market (by way of audience reach & trust) to extract large profit margins (10%-20%) from sellers and, by inflating prices across the market via commission, buyers as well. For example, the three largest French horn consignment sellers in the United States, PopeRepair, Houghton Horns, and Wichita Band all charge between 12-20% for people to sell their instruments through their consignment program. These margins on instruments that range from $3000 to $20000 place an oversize burden on sellers and artificially inflate prices in the used horn market, harming buyers.

The solution:
Blockchain smart contracts, specifically on Ethereum, are uniquely positioned to disintermediate these consignment intermediaries by automating instrument sales via escrow of Non-Fungible-Tokens that represent each instrument. Tokenized real-world assets can provide a transparent, immutable, and verifiable record of who owns an instrument and the time of purchase/transfer in order to alleviate an inefficient market currently rife with excessive consignment fees, scams, and financial fraud.

The process:
Sellers mint an NFT of the musical item they would like to sell, buyers deposit funds into the escrow smart contract, locking them until the seller has shipped the item to the buyer, who calls a one-way unlock function to release the funds from escrow to the seller, completing the sale.

Advantages:
-Horns' ownership history can easily be verified on the blockchain; this is important because some instruments were owned and played by historically significant musicians (think classical music celebrities) and their value may be appraised accordingly
-Prevent instrument scams (via automated escrow) which are prevalent on such platforms as Ebay, Etsy, Alibaba, and the like through check bounces or other financial fraud schemes.

Disadvantages:
-Since the instruments are not digital assets, much of the process must be carried out off-chain. 
-The usual pseudonymity of the crypto economy is relinquished, seeing as musicians generally don't want to operate in a trustless environment by selling to an internet stranger and would much rather openly communicate/negotiate with buyers. Luckily web3 features transparency and makes this easy.

TL;DR:

1. Seller -> smart contract                 # mints+lists NFT using website frontend w/ horn model/serialNum/other data
2. Buyer -> escrow smart contract           # deposits & locks funds to buy instrument. Oneway? DAI? USDC? ETH auction model?
3. Front-end listening for buyer 'purchase' # offchain* notifies seller by email/txt(trilio?) of 'sale'
4. Seller ships instrument to seller        # offchain* 
5. Trial period?                            # Smart contract releases escrow funds 7 days after received? buyer calls function?
6. Contract releases funds to seller        # Sale completed
7. Profit ;) 

Front-end Address: NETLIFY/HEROKU APP ADDRESS HERE

In your README.md, be sure to have clear instructions on: 
-Installing dependencies for your project 
-Accessing or—if your project needs a server (not required)—running your project
-Running your smart contract unit tests and which port a local testnet should be running on.
-A screencast of you walking through your project, including submitting transactions and seeing the updated state. You can use a screenrecorder of your choosing or something like Loom, and you can share the link to the recording in your README.md

Remember: DO NOT UPLOAD SENSITIVE INFORMATION TO GITHUB OR A PUBLIC SITE! Your Infura account details, MetaMask mnemonics, any private keys, etc., should all be in a .env file which you add to your .gitignore in your project locally. In your README.md, you should instruct the user on how to populate the .env locally with their own information.

# Testing is carried out using remix-tests CLI, as the vast majority of my tests are written in Solidity. This was done because I wanted to really delve into Solidity as a language to become fluent in it as fast as possible. The Truffle Assert library was rather limited as far as fresh test contract instantiation goes, so I opted for using the provided remix-tests beforeEach() and Assert functions to carry out tests. Only tests that are necessary off chain were done in js.
# NOTE: ```$truffle test``` will NOT compile or properly run the tests, because remix-tests is instead the dependency used for testing. First install remix-tests by running ```npm install -g @remix-project/remix-tests``` and then run ```$remix-tests --compiler 0.8.0 test``` to execute tests. This MUST be the command used to run the solidity test files in the test directory, because they rely on an injected library called "remix_tests.sol" and on the specified solidity 0.8.0 compiler.

# Note: In practice, these steps would probably require use of QR codes to communicate with frontend/contract along the way, seeing as average classical musicians know little to nothing about web3; something to consider later.
# Potential future added features: messaging (frontend), emailed/txt receipts (frontend); rent-to-own (contract), create addresses on chain to simplify UX? (frontend), ..?
