MID-SEASON CHECK-IN

For the mid-season progress check-in, please provide a short write-up that details 1) progress you made so far and 2) a timeline for open tasks that remain to be solved until submission. The mid-season progress check-in will not be included in the final evaluation.

# 0) Intro to the progress

Imagine a quiz where even the professor does not know student's answer. They know only 1 bit, if the answer was right or wrong.
A world where students will not feel embarrassed by wrong test answers. And professors feel safe, because answers do not leak. 
Interestingly, such system seems to generalize well to other problems like
finally fair NFT mints and universal on-chain gaming...

First and most important, after some drafts, it seems like I came up with an algorithm. A zero-knowledge on-chain hometask verification algorithm based on elliptic curve cryptography. 
Or we might call it a smart-contract mediated socialist-millionaire problem solution with collateral. 
The proof relies on DDH - Decisional Diffie-Hellman assumption. It holds for elliptic curves with high embedding degree where pairings are not efficiently computable. 

The difficulty was that it involes two parties student and professor. So it is a multi-party computation protocol. The professor holds a secret - the true answer. 
The hardest thing, in my idea, this answer belongs to a very small set. Might be just three options for a multiple choice test. So trusting the true answer, even hashed to a smart contract is insecure. (Salting the hash is not an option.
It works, but anyway means that the salt is a secret stored by another party) 

Even a more general statement. If there is enough information to verify the answer in the smart-contract. And we want verification to be quick. And this chain does not support secret sharing. Then such smart-contract might be dry-run.
The perpetrator could just simulate calling the contract and instantly guess which option from three was correct. That's why we anyway need at least second party to hold the secret safely.
The use-case of NARK here is to prove that each party follows the multi-party computataion protocol as it's written. The groth16 prover is implemented in the smart contract.
The contract acts as middleman. It de-incentivizes both sides for not providing the proof in time. And makes cheating meaningless and costly.

Shortly, the idea is to encode the answers by hashing to a point on the elliptic curve, and prove that both parties obeyed Diffie-Hellman exchange. 
If they could arrive at the same point it means that they started from the same point, if they could not then answers were different.

To ellaborate, P is a to-curve hash of my answer. And k is my random key. And a is professor's random key. I commit to kP and professor commited to aP'. We do proven by a circom circuit Diffie-Hellman. We get akP and akP'.
Then if they are equal we had same answers. Seems like no information leaked under Decisional Diffie-Hellman assumption. Or some sort of a multi-linear generalization, if many past tries are available in public.

# 1) Progress so far

I came up with the algorithm idea. And wrote an outline above. And implemented it in two circom circuits below.

Created a simple javascript function to hash from a string to the target curve.
Using simple try-and-increment until you find a square root residue in the target field.

And, created two circom circuits. The first "commit.circom" to commit to an encrypted answer, and key. The second "unlock.circom" to prove that I indeed used my commited key to stamp (to multiply by) professor's encrypted answer.
Professor does the same in "unlock.circom". The smart-contract oversees it. If the professor did not do checking in time. It will give me an academic credit. And vice-versa, I lose my collateral credit, if do not turn it in.
If we proved that we both were able to arrive to some point on curve. And the points match. Then my answer was right and I get an academic credit.

The 2 circuits and hashing to a curve are already available at https://github.com/arty-arty/zkMatch

<!-- BabyJubJub twisted edwards curve has a high embedding degree.
There should not be easily computable billinear or multi-linear pairing. It needs a Decisional Diffie-Hellman assumption to be true. -->

# 2) A timeline for open tasks

_____________________________________________________

1. Smart contract for Sui netowork. To verify both of the circuits "commit.circom" and "unlock.circom". Implement the incentives scheme: take collateral, burn it if not proceeded from the commit stage to unlock stage in time.
Reward for matching answers. 
(April 8)

2. A library to use the compiled circuits and communicate the results to the smart-contract on-chain.
(April 10)

3. Smart contract deployment script. Add sample questions for the demo.
(April 12)

4. Write up the proof. Explain correlation counting in a square diagram. Show how pairing billinear or multi-linear would give an ability to bruteforce the answer in no time! 
(Just for fun show how a "bad" hashing to curve will lead to point corelation and information leakage.)
(April 15)

5. Prepare a good presentation. Include the algorithm block-scheme and its proof. Illustrate a multidue of use cases: The captcha for the web3, Smart whitelisting and mint for NFTs, student-professor quizes, and porting any puzzle game to the blockchain.
Include a live demo or a video. 
(April 17)

6. (An optional point) A modified zkRepl studio. Creating a plugin by using arkworks-rs program compiled to WASM.
We need it to serialize groth16 proof point the way Sui verifier demands.
(April 20)

_____________________________________________________

April 21 is	submission 1st round deadline.

_____________________________________________________


<!-- # zkMatch 
is a solution for socialist millionaire problem mediated by an on-chain verifier. 
Let's say you want to prove that you have the same opinion as another person about some very convoluted question.
E.g. you might want to prove to your Date.

What if you do not want her to know 
Comparing to commitment hashing scheme (show immediatness like on my liked math olimpiad compared to multi-user commit break scheme)
What if you never want to reveal the true answer as professor then you need zk
Date and papers and then reveal


Say verything about verification time logatihmic though but the prving time is linear anyway and requires circuit calcualtion.
So, it would take time to prove.
IDeas like a very time consuming hash

Question answering try should be fast. Then if all the information to verify is in the contract.
Bad guy might simulate the contract. A link to hiding secrets obn public blockhains unless some secret sharing scheme is implemeted in the consensus nodes of the ntowrk.
And as the set of answerrs is small might be just two options. Bruteforce in no time!


So we need some oracle

#  The algorithm
The use-case of NARK here is to prove that each party follows the multi-party computataion protocol as it's written.


Going back to the dating example. If yours answers did not match the other party would never know

# Incentives scheme

No response NFT mint example soul animals
Money locking or paymenets whitelists, try price
Try limit for one whitlisted and KYCed man.



# Philosophy motivation

In this work for the zk-hack in Berkeley.


Playing games might be seen as 


# Caveats please notice that

In case of multiple choice questions with P1, P2, P3
theese points must not be related in a known way.

If a malicoius professor! know the relation he will be able to know the answer of his students
Show how



// Use this to fix the caveat and hash inside of the circom circuit
// https://www.youtube.com/watch?v=qWRUPzm3qPY
//file:///home/w9/Downloads/2018.100-06-01.pdf



// https://eips.ethereum.org/EIPS/eip-2494
// Conversion to Montogomery and Reduced Twisted Edwards
// For Twisted Edwards

// Elligator 
https://eprint.iacr.org/2013/325.pdf

// https://geometry.xyz/notebook/Hashing-to-the-secp256k1-Elliptic-Curve
// Sum of map_to_curves is indistinguishable from a random oracle
// https://www.researchgate.net/publication/278706125_About_Hash_into_Montgomery_Form_Elliptic_Curves

//https://www.ietf.org/archive/id/draft-irtf-cfrg-hash-to-curve-12.html#elligator2 -->




