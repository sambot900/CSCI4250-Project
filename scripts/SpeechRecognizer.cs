using Godot;
using System;
using System.Threading;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using Vosk;

// Aliases to resolve ambiguity
using SystemIO = System.IO;

public partial class SpeechRecognizer : Node
{
	[Export(PropertyHint.Dir, "The VOSK model folder")]
	string modelPath = "res://models/vosk-model-small-en-us-0.15";

	[Export(PropertyHint.None, "The name of the bus that contains the record effect")]
	string recordBusName = "Record";

	[Export(PropertyHint.None, "Stop recognition after x milliseconds")]
	long timeoutInMS = 10000;

	[Export(PropertyHint.None, "Stop recognition if there is no change in output for x milliseconds.")]
	long noChangeTimeoutInMS = 8000;

	[Export(PropertyHint.None, "Don't stop recognizer until timeout.")]
	bool continuousRecognition = false;

	[Signal]
	public delegate void OnPartialResultEventHandler(string partialResults);

	[Signal]
	public delegate void OnFinalResultEventHandler(string finalResults);

	private int recordBusIdx;
	private AudioEffectRecord _microphoneRecord;  // The microphone recording bus effect
	private bool isListening = false;
	private Model model;
	private string partialResult;
	private string finalResult;
	private ulong recordTimeStart;
	private ulong noChangeTimeOutStart;
	private CancellationTokenSource cancelToken;
	private double processInterval = 0.2;

	// Add a reference to the DebugOutputLabel
	private Label debugOutputLabel;

	public override async void _Ready()
	{
		try
		{
			// Get reference to DebugOutputLabel
			debugOutputLabel = GetNode<Label>("/root/Game/DebugOutputLabel");


			// Initialize OS-specific libraries
			IntializeOSSpecificLibs();

			// List all audio buses
			int busCount = AudioServer.BusCount;
			for (int i = 0; i < busCount; i++)
			{
				string busName = AudioServer.GetBusName(i);
			}

			// Initialize the audio recording effect
			recordBusIdx = AudioServer.GetBusIndex(recordBusName);

			if (recordBusIdx == -1)
			{
				return;
			}

			// Get the number of effects in the bus
			int effectCount = AudioServer.GetBusEffectCount(recordBusIdx);

			// Iterate through all effects to find AudioEffectRecord
			bool foundRecordEffect = false;
			for (int i = 0; i < effectCount; i++)
			{
				var effect = AudioServer.GetBusEffect(recordBusIdx, i);
				if (effect == null)
				{
					LogError($"abc123 - Effect at index {i} in '{recordBusName}' bus is null.");
					continue;
				}

				string effectType = effect.GetType().ToString();
				Log($"abc123 - Effect {i} type: {effectType}");

				if (effect is AudioEffectRecord)
				{
					_microphoneRecord = effect as AudioEffectRecord;
					Log($"abc123 - Found AudioEffectRecord at index {i}.");
					foundRecordEffect = true;
					break; // Exit loop once found
				}
			}

			if (!foundRecordEffect)
			{
				LogError("abc123 - AudioEffectRecord not found on the specified bus.");
				return;
			}

			// Copy the model files to a writable directory on Android
			string modelPathOnDevice = await PrepareModelAsync();

			if (string.IsNullOrEmpty(modelPathOnDevice))
			{
				LogError("abc123 - Failed to prepare the Vosk model.");
				return;
			}

			// Load the Vosk model
			try
			{
				model = new Model(modelPathOnDevice);
				Log("abc123 - Vosk model loaded successfully.");
			}
			catch (Exception ex)
			{
				LogError($"abc123 - Error loading Vosk model: {ex.Message}");
				return;
			}

			Vosk.Vosk.SetLogLevel(0);
			cancelToken = new CancellationTokenSource();
			Log("abc123 - Initialized Speech Recognition");
		}
		catch (Exception ex)
		{
			LogError($"abc123 - Exception in _Ready(): {ex.Message}");
		}
	}

	private static void IntializeOSSpecificLibs()
	{
		switch (OS.GetName())
		{
			case "Windows":
			case "UWP":
				NativeLibrary.Load(SystemIO.Path.Combine(AppContext.BaseDirectory, "libvosk.dll"));
				break;
			case "macOS":
				NativeLibrary.Load(SystemIO.Path.Combine(AppContext.BaseDirectory, "libvosk.dylib"));
				break;
			case "Linux":
			case "FreeBSD":
			case "NetBSD":
			case "OpenBSD":
			case "BSD":
				NativeLibrary.Load(SystemIO.Path.Combine(AppContext.BaseDirectory, "libvosk.so"));
				break;
			case "Android":
				NativeLibrary.Load(SystemIO.Path.Combine(AppContext.BaseDirectory, "libvosk.so"));
				break;
			case "iOS":
				GD.PrintErr("No iOS Support");
				break;
			case "Web":
				GD.PrintErr("No Web Support");
				break;
		}
	}

	private async Task<string> PrepareModelAsync()
	{
		if (OS.GetName() == "Android")
		{
			// On Android, copy the model files to a writable directory
			var targetPath = SystemIO.Path.Combine(OS.GetUserDataDir(), "vosk_models", "model");

			Log($"abc123 - Android model path: {targetPath}");

			if (!SystemIO.Directory.Exists(targetPath) || !SystemIO.File.Exists(SystemIO.Path.Combine(targetPath, "README.md")))
			{
				Log("abc123 - Copying Vosk model files to internal storage...");

				var success = await CopyModelFilesAsync(modelPath, targetPath);

				if (!success)
				{
					LogError("abc123 - Failed to copy Vosk model files.");
					return null;
				}

				Log("abc123 - Vosk model files copied successfully.");
			}
			else
			{
				Log("abc123 - Vosk model files already exist in internal storage.");
			}

			return targetPath;
		}
		else
		{
			// For other platforms, use the model directly from the resource path
			var globalPath = ProjectSettings.GlobalizePath(modelPath);
			Log($"abc123 - Non-Android global model path: {globalPath}");
			return globalPath;
		}
	}

	private async Task<bool> CopyModelFilesAsync(string sourcePath, string targetPath)
	{
		try
		{
			var dir = DirAccess.Open(sourcePath);
			if (dir == null)
			{
				LogError($"abc123 - Failed to open source directory: {sourcePath}");
				return false;
			}

			if (!SystemIO.Directory.Exists(targetPath))
			{
				SystemIO.Directory.CreateDirectory(targetPath);
				Log($"abc123 - Created target directory: {targetPath}");
			}

			dir.ListDirBegin();

			string fileName = dir.GetNext();
			while (fileName != string.Empty)
			{
				if (fileName == "." || fileName == "..")
				{
					fileName = dir.GetNext();
					continue;
				}

				string sourceFilePath = SystemIO.Path.Combine(sourcePath, fileName);
				string targetFilePath = SystemIO.Path.Combine(targetPath, fileName);

				if (dir.CurrentIsDir())
				{
					// Recursively copy subdirectories
					Log($"abc123 - Copying directory: {sourceFilePath} to {targetFilePath}");
					await CopyModelFilesAsync(sourceFilePath, targetFilePath);
				}
				else
				{
					// Copy file
					var file = FileAccess.Open(sourceFilePath, FileAccess.ModeFlags.Read);
					if (file != null)
					{
						byte[] data = file.GetBuffer((long)file.GetLength());
						file.Close();

						// Write to the target file
						var targetFile = FileAccess.Open(targetFilePath, FileAccess.ModeFlags.Write);
						if (targetFile != null)
						{
							targetFile.StoreBuffer(data);
							targetFile.Close();
							Log($"abc123 - Copied file: {sourceFilePath} to {targetFilePath}");
						}
						else
						{
							LogError($"abc123 - Failed to open file for writing: {targetFilePath}");
						}
					}
					else
					{
						LogError($"abc123 - Failed to open file for reading: {sourceFilePath}");
					}
				}

				fileName = dir.GetNext();
			}

			dir.ListDirEnd();

			return true;
		}
		catch (Exception ex)
		{
			LogError($"abc123 - Exception during model file copy: {ex.Message}");
			return false;
		}
	}

	// Methods to start and stop speech recognition
	public void StartSpeechRecognition()
	{
		if (cancelToken != null && !cancelToken.IsCancellationRequested)
		{
			cancelToken.Cancel();
		}
		cancelToken = new CancellationTokenSource();
		partialResult = "";
		finalResult = "";
		recordTimeStart = Time.GetTicksMsec();
		noChangeTimeOutStart = Time.GetTicksMsec();
		isListening = true;
		if (_microphoneRecord != null)
		{
			if (!_microphoneRecord.IsRecordingActive())
			{
				_microphoneRecord.SetRecordingActive(true);
			}
		}
		else
		{
			return;
		}
		StartContinuousSpeechRecognition();
	}

	public string StopSpeechRecognition()
	{
		isListening = false;
		cancelToken.Cancel();
		if (_microphoneRecord != null && _microphoneRecord.IsRecordingActive())
		{
			_microphoneRecord.SetRecordingActive(false);
		}
		return finalResult;
	}

	// Method to check if currently listening
	public bool IsCurrentlyListening()
	{
		return isListening;
	}

	private void StartContinuousSpeechRecognition()
	{
		_ = Task.Run(async () =>
		{
			try
			{
				while (!cancelToken.IsCancellationRequested)
				{
					await Task.Delay(TimeSpan.FromSeconds(processInterval), cancelToken.Token);
					ProcessMicrophone();
					ulong currentTime = Time.GetTicksMsec();
					if (!continuousRecognition && isListening && (currentTime - noChangeTimeOutStart) > (ulong)noChangeTimeoutInMS)
					{
						StopSpeechRecognition();
						GD.PrintErr("Mic Timeout");
						
					}
					else if (isListening && (currentTime - recordTimeStart) >= (ulong)timeoutInMS)
					{
						StopSpeechRecognition();
						GD.PrintErr("Mic Timeout");
					}
				}
			}
			catch (TaskCanceledException)
			{
			}
			catch (Exception ex)
			{
			}
		});
	}

	private void ProcessMicrophone()
	{
		if (_microphoneRecord != null && _microphoneRecord.IsRecordingActive())
		{
			var recordedSample = _microphoneRecord.GetRecording();
			if (recordedSample != null)
			{
				VoskRecognizer recognizer = new VoskRecognizer(model, recordedSample.MixRate);
				byte[] data = recordedSample.Stereo ? MixStereoToMono(recordedSample.Data) : recordedSample.Data;
				if (!recognizer.AcceptWaveform(data, data.Length))
				{
					string currentPartialResult = recognizer.PartialResult();
					if (partialResult == null || !currentPartialResult.Equals(partialResult))
					{
						partialResult = currentPartialResult;
						noChangeTimeOutStart = Time.GetTicksMsec();
						CallDeferred("emit_signal", "OnPartialResult", partialResult);
					}
				}
				else if (!continuousRecognition) // Completed recognition
				{
					EndRecognition(recognizer);
					StopSpeechRecognition();
				}
				recognizer.Dispose(); // Cleanup
			}
		}
	}

	private void EndRecognition(VoskRecognizer recognizer)
	{
		finalResult = recognizer.FinalResult();
		recognizer.Dispose(); // Cleanup
		CallDeferred("emit_signal", "OnFinalResult", finalResult);
	}

	// Added MixStereoToMono method to handle stereo data
	private byte[] MixStereoToMono(byte[] input)
	{
		if (input.Length % 4 == 0)
		{
			byte[] output = new byte[input.Length / 2];
			int outputIndex = 0;
			for (int n = 0; n < input.Length; n += 4)
			{
				int leftChannel = BitConverter.ToInt16(input, n);
				int rightChannel = BitConverter.ToInt16(input, n + 2);
				int mixed = (leftChannel + rightChannel) / 2;
				byte[] outSample = BitConverter.GetBytes((short)mixed);

				output[outputIndex++] = outSample[0];
				output[outputIndex++] = outSample[1];
			}
			return output;
		}
		else
		{
			return input;
		}
	}

	// Logging methods with unique identifiers for easier search
	private void Log(string message)
	{
		GD.Print(message);
		if (debugOutputLabel != null)
		{
			CallDeferred(nameof(UpdateDebugLabel), message);
		}
	}

	private void LogError(string message)
	{
		GD.PrintErr(message);
		if (debugOutputLabel != null)
		{
			CallDeferred(nameof(UpdateDebugLabel), message);
		}
	}

	private void UpdateDebugLabel(string message)
	{
		debugOutputLabel.Text += message + "\n";
	}

	public override void _Notification(int what)
	{
		if (what == NotificationWMCloseRequest)
		{
			model?.Dispose();
			GetTree().Quit(); // Default behavior
		}
	}
}
