PROCESS(stock_market)
	
/controller/process/stock_market/setup()
	name = "Stock Market"
	schedule_interval = 15

/controller/process/stock_market/doWork()
	if (stockExchange)
		stockExchange.process()

