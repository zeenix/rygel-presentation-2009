all: librygel-test.so

librygel-test.so: rygel-test-plugin.c
	gcc `pkg-config --cflags rygel-1.0` \
	-shared -o rygel-test.so $^

rygel-test-plugin.c: rygel-test-plugin.vala
	valac -C --pkg rygel-1.0 $^

clean:
	rm -f *.c *.so

