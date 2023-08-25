# tnt3-app
## Description
App based on tarantool 3.0.0-alpha2. Supports replication and sharding options.

## Preparing
**Install vshard**
```sh
tt rocks install vshard
```
**Start cluster**
```sh
tarantool -c config.yml -n router-001 &
tarantool -c config.yml -n storage-001 &
tarantool -c config.yml -n storage-002 &
tarantool -c config.yml -n storage-011 &
tarantool -c config.yml -n storage-012 &
```

**Bootstrap storages**
Here we create space with indexes on masters and define CRUD-like operations.
```sh
tt connect client:secret@127.0.0.1:3301 <<EOF
    box.schema.space.create("test", {if_not_exists = true})
    box.space.test:format({
         {name = "id", type="unsigned"},
         {name = "bucket_id", type="unsigned"},
         {name = "value", type="string"},
     })
    box.space.test:create_index("pri", {parts = {'id'}}, {if_not_exists = true})
    box.space.test:create_index("bucket_id", {parts = {'bucket_id'}, unique = false}, {if_not_exists = true})

    function put(...)
        return box.space.test:put(...)
    end

    function get(id)
        return box.space.test:get({id})
    end

    function pull(id, limit)
        limit = tonumber(limit) or 10
        limit = math.min(limit, 1000)
        return box.space.test:select({id}, {iterator="GE", limit=limit})
    end
EOF

tt connect client:secret@127.0.0.1:3302 <<EOF
    function get(id)
        return box.space.test:get({id})
    end

    function pull(id, limit)
        limit = tonumber(limit) or 10
        limit = math.min(limit, 1000)
        return box.space.test:select({id}, {iterator="GE", limit=limit})
    end
EOF

tt connect client:secret@127.0.0.1:3311 <<EOF
    box.schema.space.create("test", {if_not_exists = true})
    box.space.test:format({
         {name = "id", type="unsigned"},
         {name = "bucket_id", type="unsigned"},
         {name = "value", type="string"},
     })
    box.space.test:create_index("pri", {parts = {'id'}}, {if_not_exists = true})
    box.space.test:create_index("bucket_id", {parts = {'bucket_id'}, unique = false}, {if_not_exists = true})

    function put(...)
        return box.space.test:put(...)
    end

    function get(id)
        return box.space.test:get({id})
    end

    function pull(id, limit)
        limit = tonumber(limit) or 10
        limit = math.min(limit, 1000)
        return box.space.test:select({id}, {iterator="GE", limit=limit})
    end
EOF

tt connect client:secret@127.0.0.1:3312 <<EOF
    function get(id)
        return box.space.test:get({id})
    end

    function pull(id, limit)
        limit = tonumber(limit) or 10
        limit = math.min(limit, 1000)
        return box.space.test:select({id}, {iterator="GE", limit=limit})
    end
EOF
```

After that each of the shards will have `put`, `pull` and `get` functions.

**Bootstrap router**
```sh
tt connect client:secret@127.0.0.1:3300 <<EOF
vshard = require('vshard')
vshard.router.bootstrap()
EOF
```

## Playing around
Now you can try to play with data, for example:

```sh
$ tt connect client:secret@127.0.0.1:3300
   • Connecting to the instance...
   • Connected to 127.0.0.1:3300

127.0.0.1:3300> for i = 0, 10 do
    local bucket_id = vshard.router.bucket_id_strcrc32(i)
    vshard.router.callrw(bucket_id, "put", {{i, bucket_id, "data " .. i}})
end
---
...

127.0.0.1:3300>
$ tt connect client:secret@127.0.0.1:3300
   • Connecting to the instance...
   • Connected to 127.0.0.1:3300

127.0.0.1:3300> vshard.router.map_callrw("pull", {1, 10})
---
- e1ae6beb-8d26-4bb7-00fc-7ccf4eec92df:
  - [[1, 2477, 'data 1'], [2, 1401, 'data 2'], [3, 1804, 'data 3'], [5, 1172, 'data
        5'], [6, 3064, 'data 6'], [8, 3185, 'data 8']]
  f787fd14-fbfd-6f3f-0002-6276754f995f:
  - [[4, 8161, 'data 4'], [7, 6693, 'data 7'], [9, 6644, 'data 9'], [10, 8569, 'data
        10']]
...

```


