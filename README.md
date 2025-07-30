# Beta

## Response to Design Explorations
I got disconnected while having a thought "discussions again" and seeing "one" solution for all the ideas spoken.
This inspired me to sit in the night and implement my vision of oracles infra.
Didn't have time to finish it yet, so here is some beta version for yet another discussion, ha-ha.

### Upgradable oracles
`Weighted` oracle supports smooth onboarding and offboarding of oracles.
Manager role is introduced to make oracle more robust by adding "secondary" price sources.

### Smoothed Chainlink
Confidence of oracle is dependent on staleness.
Though new data spikes are not supported (yet?).

### Fallback Oracle
By using several weighted sources it can be automatically disabled.

#### Onchain condition
Each oracle reports its confidence according to TVL or other parameters.
This parameter is smoothed w.r.t. `TARGET_TVL`.

#### Offchain condition
Manager's role is introduced for this type of scenarios.

### Ranged Oracle (bounds)
Open question but the idea is to provide *confidence interval* of `.confidence()`.

### Impact Based Oracle
Can be implemented using confidence, confidence intervals and different calculators for weighted oracle.

### Dual Oracle
This would need to different setups :(

# About
Price oracles are a trust problem.
Each oracle has its risks represented in confidence of value returned.
This way we map the risks to some measure (value from 0 to 1) and then use basic models/formulas to get the final answer.
Connected oracle should have confidence of one nature to be compatible, so open questions:
- [ ] choose nature or classes of nature for confidence
- [ ] choose models to properly combine these confidences(calculators in weighted price oracle)
- [ ] find confidence intervals to provide bounds

## Contributing

### Install
Install python dependencies using [uv](https://github.com/astral-sh/uv):

```shell
uv sync
```

To enter the python environment:

```shell
source .venv/bin/activate
```

### Test
```shell
uv run pytest .
```
Forked and slow stateful tests are disabled by default. To include them, use the --forked or --slow flags. For example, to run all tests:
```shell
uv run pytest --forked --slow
```

### Run
You can find keeper scripts in [scripts/](scripts) directory.
