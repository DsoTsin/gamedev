Writer_ControlRecv <- Writer_UpdateControl <- Writer_WorkerUpdateInternal <- Writer_WorkerUpdate <- Writer_WorkerThread
<- Writer_WorkerJoin
<- Writer_Update <- UE::Trace::Update() [When worker thread is not launched.] <- FCoreDelegates::OnEndFrame.AddStatic(UE::Trace::Update);
                                        <- MemoryTrace_UpdateInternal()
一个是WorkerThread，一个是WorkerThread没启动的时候去调用

初始化
Writer_InitializeControl()


	Writer_ControlAddCommand("ConsoleCommand", nullptr,
		[] (void*, uint32 ArgC, ANSICHAR const* const* ArgV)
		{
			if (ArgC < 2)
			{
				return;
			}

			const size_t BufferSize = 512;
			ANSICHAR Channels[BufferSize] = {};
			ANSICHAR* Ctx;
			const bool bState = (ArgV[1][0] != '0');
			FCStringAnsi::Strcpy(Channels, BufferSize, ArgV[0]);
			ANSICHAR* Channel = FCStringAnsi::Strtok(Channels, ",", &Ctx);
			while (Channel)
			{
				FChannel::Toggle(Channel, bState);
				Channel = FCStringAnsi::Strtok(nullptr, ",", &Ctx);
			}
		}
	);