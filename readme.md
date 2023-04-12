# zkMatch 
is a two-party system to prove encrypted information match.

Two millionaires want to see if they have equal wealth without disclosing how rich they are. This is Social-Millionaire problem.
Here is my solution using NIZK proofs and eliptic curves. I implement it inside of a smart contract.

Surprisingly, once on a blockchain, this has a multidue applications: homework assignment verification, thinking biger, a way to port any puzzle game to blockchain, and even a web3 captcha to protect against dangers of AI.

# The algorithm shortly

A point on an elliptic curve denotes the right answer. If a human and captcha server, using groth16, prove
that they did a Diffie-Hellman key exchange, and they arrived at the same point, then the answer is right. 

# When it works 

The proof relies on DDH - Decisional Diffie-Hellman assumption. It holds for elliptic curves with high embedding degree where pairings are not efficiently computable. 

# Why non-trivial

The difficulty was that it involes two parties, say, student and professor. So it is a multi-party computation protocol. The professor holds a secret - the true answer. The hardest thing, this answer belongs to a very small set. Might be just three options for a multiple choice test.

So, trusting the true answer, even hashed to a smart contract is insecure. (Salting the hash is not an option.
It works, but anyway means that the salt is a secret stored by another party) 

Even a more general statement. If there is enough information to verify the answer in the smart-contract. And we want verification to be quick. And this chain does not support secret sharing. Then such smart-contract might be dry-run. The perpetrator could just simulate calling the contract and instantly guess which option from three was correct. That's why we anyway need at least second party to hold the secret safely.

# Why zkNARK

The use-case of NARK here is to prove that each party follows the multi-party computataion protocol as it's written. The groth16 prover is implemented in the smart contract. The contract acts as middleman. It de-incentivizes both sides for not providing the proof in time. And makes cheating meaningless and costly.

# A bit more details on the algorithm

Shortly, the idea is to encode the answers by hashing to a point on the elliptic curve, and prove that both parties obeyed Diffie-Hellman exchange. 
If they could arrive at the same point it means that they started from the same point, if they could not then answers were different.

To ellaborate, P is a to-curve hash of my answer. And k is my random key. And a is professor's random key. I commit to kP and professor commited to aP'. We do proven by a circom circuit Diffie-Hellman. We get akP and akP'.
Then if they are equal we had same answers. Seems like no information leaked under Decisional Diffie-Hellman assumption. Or some sort of a multi-linear generalization, if many past tries are available in public.
