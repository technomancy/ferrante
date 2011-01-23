curl -XPOST "http://localhost:8080/follow?id=1"
curl -I -XPUT "http://localhost:8080/follow?id=1&latitude=40&longitude=-122&name=follower"
# curl -I -XDELETE "http://localhost:8080/follow?id=1&name=leader"
