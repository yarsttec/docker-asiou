CACHEOPS_REDIS = "redis://127.0.0.1:6379/0"
CACHEOPS_DEFAULTS = {
    'timeout': 60*60,
}
CACHEOPS = {
    # 'dict.*': {'ops': 'get'},
    'auth.user': {'ops': 'all', 'timeout': 24*60*60},
    'institute.asiou_institute': {'ops': 'all', 'timeout': 24*60*60, 'local_get': True},
    'properties.asiou_p_params': {'ops': 'all', 'timeout': 24*60*60, 'local_get': True},
    'properties.asiou_p_values_list': {'ops': 'all', 'timeout': 24*60*60, 'local_get': True},
    'properties.asiou_p_object_types': {'ops': 'all', 'timeout': 24*60*60},
    # '*.*': {'ops': {'fetch', 'get'}},
}
CACHEOPS_DEGRADE_ON_FAILURE = True
CACHEOPS_LRU = True
