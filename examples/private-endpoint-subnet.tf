virtual_networks = {
  vnet1 = {
    address_space = {
      dev = ["10.30.1.0/24"]
    }
  }
  vnet2 = {
    address_space = {
      dev = ["10.30.2.128/25"]
    }
  }
  vnet3 = {
    address_space = {
      dev = ["10.30.3.0/28", "10.30.4.0/24"]
    }
  }
}
