tt connect client:secret@127.0.0.1:3300 <<EOF
for i = 0, 10 do
    local bucket_id = vshard.router.bucket_id_strcrc32(i)
    vshard.router.callrw(bucket_id, "put", {{i, bucket_id, "data " .. i}})
end
EOF

tt connect client:secret@127.0.0.1:3300 <<EOF
vshard.router.map_callrw("pull", {1, 10})
EOF
