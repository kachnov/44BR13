PROCESS(stock_market)
	priority = PROCESS_PRIORITY_STOCK_MARKET
	
/controller/process/stock_market/setup()
	name = "Stock Market"
	schedule_interval = 1.5 SECONDS

/controller/process/stock_market/doWork()
	if (stockExchange)
		stockExchange.process()

