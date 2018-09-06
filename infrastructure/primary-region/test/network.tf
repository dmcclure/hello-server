# Fetch AZs in the current region
data "aws_availability_zones" "available" {}

# Create private subnets, each in a different AZ. We'll run our applications in these subnets.
resource "aws_subnet" "private" {
  # count             = "${var.az_count > 3 ? 3 : var.az_count}"
  # count             = "${length(data.aws_availability_zones.available.id) > 3 ? 3 : length(data.aws_availability_zones.available.id)}"
  # count             = "${min(length(data.aws_availability_zones.available.id), 3)}"
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.main.id}"
  tags {
    Name = "hello-server-private-${data.aws_availability_zones.available.names[count.index]}-${var.environment}"
  }
}

# Create public subnets, each in a different AZ. We'll run our public-facing load balancers in these subnets.
resource "aws_subnet" "public" {
  # count                   = "${var.az_count > 3 ? 3 : var.az_count}"
  # count                   = "${min(length(data.aws_availability_zones.available.id), 3)}"
  count                   = "${var.az_count}"
  cidr_block              = "${cidrsubnet(aws_vpc.main.cidr_block, 8, var.az_count + count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id                  = "${aws_vpc.main.id}"
  map_public_ip_on_launch = true
  tags {
    Name = "hello-server-public-${data.aws_availability_zones.available.names[count.index]}-${var.environment}"
  }
}

# Internet gateway for the public subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
}

# Route the public subnet trafic through the internet gateway
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.main.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

# Create a NAT gateway with an elastic IP for each private subnet to get internet connectivity
resource "aws_eip" "nat_gateway" {
  count      = "${var.az_count}"
  vpc        = true
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "gw" {
  count         = "${var.az_count}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  allocation_id = "${element(aws_eip.nat_gateway.*.id, count.index)}"
}

# Create a new route table for the private subnets, and make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = "${var.az_count}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.gw.*.id, count.index)}"
  }
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count          = "${var.az_count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}