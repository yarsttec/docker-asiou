CACHEOPS_REDIS = "redis://127.0.0.1:6379/0"
CACHEOPS_DEFAULTS = {
    'timeout': 60*60,
}
CACHEOPS = {
    # 'dict.*': {'ops': 'get'},
    'properties.asiou_p_params': {'ops': 'all', 'timeout': 24*60*60, 'local_get': True},
    # '*.*': {'ops': {'fetch', 'get'}},
}
CACHEOPS_DEGRADE_ON_FAILURE = True
CACHEOPS_LRU = True
