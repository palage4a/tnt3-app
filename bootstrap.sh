tarantool -c config.yml -n router-001 &
tarantool -c config.yml -n storage-001 &
tarantool -c config.yml -n storage-002 &
tarantool -c config.yml -n storage-011 &
tarantool -c config.yml -n storage-012 &

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

tt connect client:secret@127.0.0.1:3300 <<EOF
vshard = require('vshard')
vshard.router.bootstrap()
EOF
