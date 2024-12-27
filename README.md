# Only-Investors 🧑‍🦲📈💰
### Fostering talent.

<img src="./imgResources/logo.webp" alt="only-investors-logo" width="150">

---

Because **financial stability** allows you to plan a **better future**. Here I present:

Only Investors
(Motto: Fostering talent)

A platform to invest on People (generally, income sources).

This is how it works, simple, powerful, beautiful:

1.- Some worker (let’s say a smart contract auditor) creates its own rewards token.

2.- You as an investor can buy that token. (the worker gets some income, the worker sets the price)

3.- You will get X% of the worker’s future income which will be distributed to reward token holders. (auditors usually receive their payouts at a certain address, the address can perfectly be a smart contract that redirects X% of the funds to investors to assure payouts)

Workers will set the conditions of profitability of their future work, and if you deem them nice, just buy the tokens, get your share and wait until your investment yields profit. In the meanwhile, the worker will have more capital to invest on himself, his work and overall leading to a more thoughtful and cared product created by a relaxed and stable worker.

Sure the worker can always laze around and do a shit, but this is like buying a stock, giving money to the company in expect of future returns, the company can just do shit too.

Let’s democratize access to capital at an individual level and improve the capital efficiency while promoting happier talented workers around the world!

<img src="./imgResources/v1-architechture.png" alt="v1-architecture">

---

## Project Goal

This aims to be public-infrastructure to decentralize investment on income sources.


I will answer some stuff, kalogerone feel free to answer too, correcting me or add stuff on top of mine. In my opinion I consider this a Medium.

The main argumets provided for this to be a Low are:

- 1️⃣ The attack is a grief with no profit motive.
- 2️⃣ Forcing a swap in another address is not high impact.
- 3️⃣ Keeper allowance decreased unfairly is like keeper being unexpectedly down == low.
- 4️⃣ _99.99%_ is not realistic. Which leads to the discussion of what parameters were valid and what not-

### 1️⃣

This is the only reason why it might not be a High. I could not find anywhere in cantina docs (maybe there is, judge will say) where it says griefing is low impact.

### 2️⃣

We are altering a users approvals to the project and also changing his token balances at will. I'm not an expert on the technical details of the issue as my team-mate was assigned to write the report for this one. Yet as of my understanding:

It is true that the only potential loss of this grief is gas costs and fees of the swapped tokens. So, true from within the project POV the loss is not that high. But **forcing someone to spend more money than they should without their will** is, to me, a clear Medium.

Furthermore, **in the broader blockchain ecosystem, the victim's address can have their token balances changed at any time**. Imagine the victim is going to use his cash for X in any other project or tx, that is what he takes the loan for really. Then you forcefully make the oracle swap that, **the victim has lost complete sovereignty over with which token he holds his blockchain value**. This is what makes this swap thing a really worrying thing in my opinion.

A user can take a loan and that loan's tokens can be swapped at any time if someone decides to grief, you don't really own those tokens if anyone can manipulate them through the oracle. If there was 0 cost it is clearly a high, but as it is grief I understand someone can see it as Medium, but not a low at all in my opinion for the reasons explained.

### 3️⃣

Now talking about altering the keeper allowance and the keeper being unexpectedly down. Yes, it is unexpected, they key resides on the reason of that unexpected downtime. The reason is not that the keeper is not working or is turned off, is that anyone is altering your approvals to it and thus choosing whether you can still use the keeper for the rest of your loans or not.

I clearly see this as breaking one of the protocol features, medium. But again as it has a grief component I understand if someone puts this other negative impact a step lower to low.

### 4️⃣

About 99.99% being obvious. This is not how audits work. You gotta be really clear on what we are auditing.

We are not here to audit what the code is supposed to and "obviously" does, if so all codes would be perfect, we are here to audit what the code actually does, which might and most of the times will be different from what the developers think it obviously does, this is what auditing is. Given an expected coded and documented behavior find behaviors that are not expected and fix them if deemed malicious.

That is why you can't just say it is obvious when there is no code that backs this up, neither comments on the code, neither in the contest conditions. We are not supposed to assume things are obvious and work and always behave the obvious way, that is not our job. All assumptions (== obvious stuff) must be documented. In real life a hacker won't stop and think oh this exploit is not obvious and not do it, he will just see what the code actually does and exploit it. That is what auditors do, read the code as a hacker and see what it does, not imagine what the code does, that is why all assumptions, no matter how obvious they might seem must be documented. 

### Conclusion

Due to the impacts 2️⃣ (high impact if no grief) and 3️⃣ (medium impact if no grief), yet because 1️⃣ (grief) is a thing I think the correct rating is Medium. Being the reason with higher weight the loss of sovereignty from the victim over his token balances.

And regarding 4️⃣ any argument that uses it to conclude that the impact is Low it is incredibly unfair to the auditors. Because it is effectively changing the contest conditions to more strict ones right after the contest ends which leads to affect valid issues with valid work thus causing auditors loss of time, money, reputation and overall very bad and unfair working conditions. Making this not a fair competition but a extracting free labor security review. 
