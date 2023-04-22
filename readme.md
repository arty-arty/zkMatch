# zkMatch 
is a two-party system to prove encrypted information match. It is a building block for verified gaming.

Two millionaires want to see if they have equal wealth without disclosing how rich they are. This is Social-Millionaire problem.
Here is my solution using NIZK proofs and eliptic curves. I implement it inside of a smart contract.

Surprisingly, once on a blockchain, this has a multidue applications: homework assignment verification, thinking biger, a way to port any puzzle game to blockchain, and even a web3 captcha to protect against the dark side of AI - robots.

# So how does verified match help games?

There are games to tell stories. There are games to solve mysteries. But actually, games are just tasks that require one to act in a specific way - to answer some question. 

If there is only one way to solve a level - only one answer - then zkMatch works. 
Any such game old or new can, actually, be run on-chain. Which brings a host of possibilities like - guaranteed rewards, abolished cheating. It can be placing mirrors to guide the laser through the labirynth. It can be finding one concept which unites four pictures. It can be guessing which brand is on the logo. This a general solution to rule them all.

# Demo
is an application of this principle. Here it is an NFT minting game. With a difficult puzzle only human can solve to protect against bots.

A [demo is hosted here](https://cheerful-cheesecake-30269e.netlify.app/). It needs my computer running the oracle. So, here is a [YouTube demo variant](https://youtu.be/PdydslqjhMo), just in case.

# The algorithm shortly

A point on an elliptic curve denotes the right answer. Here I implemented simple [try-and-increment encoding](https://github.com/arty-arty/zkMatch/blob/master/boneh-encode/hash_to_curve.js). If a human and captcha server, using groth16, prove
that they did a Diffie-Hellman key exchange, and they arrived at the same point, then the answer is right. 

Those two circuits: the first one for initial commitment to the key, and the second for proven multiplication are
in: [commit.circom](https://github.com/arty-arty/zkMatch/blob/master/commit.circom) and [unlock.circom](https://github.com/arty-arty/zkMatch/blob/master/unlock.circom)

# When it works 

The proof relies on DDH - Decisional Diffie-Hellman assumption. It holds for elliptic curves with high embedding degree where pairings are not efficiently computable. 

# Why non-trivial

The difficulty was that it involes two parties, say, student and professor. So it is a multi-party computation protocol. The professor holds a secret - the true answer. The hardest thing, this answer belongs to a very small set. Might be just three options for a multiple choice test.

So, trusting the true answer, even hashed to a smart contract is insecure. (Salting the hash is not an option.
It works, but anyway means that the salt is a secret stored by another party) 

Even a more general statement. If there is enough information to verify the answer in the smart-contract. And we want verification to be quick. And this chain does not support secret sharing. Then such smart-contract might be dry-run. The perpetrator could just simulate calling the contract and instantly guess which option from three was correct. That's why we anyway need at least second party to hold the secret safely.

# Why zkNARK

The use-case of NARK here is to prove that each party follows the multi-party computataion protocol as it's written. The groth16 prover is implemented in [the smart contract, please see it.](https://github.com/arty-arty/zkMatch/blob/master/sui-verifier/sources/dev_verifier.move) The contract acts as middleman. It de-incentivizes both sides for not providing the proof in time. And makes cheating meaningless and costly.

# A bit more details on the algorithm

Shortly, the idea is to encode the answers by hashing to a point on the elliptic curve, and prove that both parties obeyed Diffie-Hellman exchange. 
If they could arrive at the same point it means that they started from the same point, if they could not then answers were different.

To ellaborate, P is a to-curve hash of my answer. And k is my random key. And a is professor's random key. I commit to kP and professor commited to aP'. We do proven by a circom circuit Diffie-Hellman. We get akP and akP'.
Then if they are equal we had same answers. Seems like no information leaked under Decisional Diffie-Hellman assumption. Or some sort of a multi-linear generalization, if many past tries are available in public.
