from config import CONFIG
from redis import Redis 
redis = Redis(
    host=CONFIG.REDIS.HOST,
    port=CONFIG.REDIS.PORT,
    password=CONFIG.REDIS.PASSWORD
)


