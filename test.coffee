###
{id_b65, b64_id, num_b64} = require 'cloud/_lib/b64'

console.log b64_id id_b64('55892bafe4b0416bdfc44c89')
console.log num_b64 1000

redis = require "cloud/_redis"
{R} = redis
R "PostStar"
setTimeout(
    ->
        console.log R.PostStar
        redis.smismember R.PostStar+'-'+"5554f671e4b076f1c3451b9b", [ 99289, 99286, 99285, 99284, 99283, 99281, 99280, 99278, 99277, 99276, 99272, 99269, 99268, 99267, 99266, 99261, 99253, 99251, 99250, 99249 ], (err, result)->
            console.log err, result
    1000
)

###

require "cloud/db/sync"
{id_bin,bin_id} = require "cloud/_lib/b64"

