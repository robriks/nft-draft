NFT Marketplace & Escrow Contract for Classical Musicians
by robriks github.com/robriks/consensys-academy-final-project
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

# Note: In practice, these steps would probably require use of QR codes to communicate with frontend/contract along the way, seeing as average classical musicians know little to nothing about web3; something to consider later.
# pretty formatting later
# Potential added features: messaging (frontend), emailed/txt receipts (frontend); rent-to-own (contract), create addresses on chain to simplify UX? (frontend), ..?
