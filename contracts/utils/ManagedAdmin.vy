# pragma version 0.4.3

from snekmate.auth import ownable

initializes: ownable
exports: (
    ownable.owner,
    ownable.transfer_ownership,
)


event AddManager:
    manager: address


event RemoveManager:
    manager: address


roles: HashMap[address, bool]


@deploy
def __init__():
    ownable.__init__()


def _check_manager(caller: address = msg.sender):
    assert self._is_manager(caller), "No manager rights"


@view
def _is_manager(caller: address) -> bool:
    return self.roles[caller]


@external
def add_manager(_manager: address):
    self._check_owner()
    self._add_manager(_manager)


@external
def remove_manager(_manager: address):
    self._check_owner()
    self._remove_manager(_manager)


def _add_manager(manager: address):
    self.roles[manager] = True
    log AddManager(manager=manager)


def _remove_manager(manager: address):
    self.roles[manager] = False
    log RemoveManager(manager=manager)


# export inner function, Vyper restriction


def _check_owner():
    ownable._check_owner()
