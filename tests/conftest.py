import pytest
import boa

boa.env.enable_fast_mode()

EMPTY_BYTES32 = "0x0000000000000000000000000000000000000000000000000000000000000000"
EMPTY_ADDRESS = "0x0000000000000000000000000000000000000000"

DAY = 86400
WEEK = 7 * DAY

pytest_plugins = [
    "shared.forked.fixtures",
]


def pytest_addoption(parser):
    parser.addoption(
        "--forked", action="store_true", default=False, help="Run tests in forked environment"
    )
    parser.addoption("--slow", action="store_true", default=False, help="Run tests marked as slow")


def pytest_collection_modifyitems(config, items):
    # Skip tests in `forked/` directories unless --forked is provided
    if not config.getoption("--forked"):
        skip_forked = pytest.mark.skip(reason="Skipping forked tests. Use --forked to enable them.")
        for item in items:
            if item.path and "/forked/" in str(item.path):
                item.add_marker(skip_forked)

    # Skip slow tests unless --slow is provided
    if not config.getoption("--slow"):
        skip_slow = pytest.mark.skip(reason="Skipping slow tests. Use --slow to run them.")
        for item in items:
            if "slow" in item.keywords:
                item.add_marker(skip_slow)


@pytest.fixture(scope="session")
def alan():
    """
    "We shall not go any further into the nature of this oracle apart from saying that it cannot be a machine."
    – Alan Turing
    """
    return boa.env.generate_address()


@pytest.fixture(scope="session")
def kurt():
    """
    "Either mathematics is too big for the human mind or the human mind is more than a machine."
    – Kurt Gödel
    """
    return boa.env.generate_address()


@pytest.fixture(scope="session")
def admin():
    return boa.env.generate_address()


@pytest.fixture(scope="session")
def manager():
    return boa.env.generate_address()
