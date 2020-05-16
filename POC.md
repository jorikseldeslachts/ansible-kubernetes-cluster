
# POC: what master to use (certs, join command, ...)

- var main_master setten


CASE | VALUE
--|--
full install | main_master = groups['masters'][0]
add master   | main_master = set manually
add worker   | main_master = set manually


