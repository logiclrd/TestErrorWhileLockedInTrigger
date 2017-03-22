using System;
using System.Data;
using System.Data.SqlClient;
using System.Transactions;

namespace TestErrorWhileLockedInTrigger
{
	class Program
	{
		static void Main(string[] args)
		{
			// Test without exclusive lock on table
			Test(shouldLockTable: false);

			// Test with exclusive lock on table
			// NB: When executed through SSMS, this *does* appear to report the error properly
			Test(shouldLockTable: true);
		}

		static void Test(bool shouldLockTable)
		{
			Console.WriteLine("------");
			Console.WriteLine("Beginning test {0} exclusive lock on table within the trigger", shouldLockTable ? "WITH" : "WITHOUT");

			bool gotExpectedError = false;
			bool transactionCompleted = false;

			try
			{
				using (var transaction = new TransactionScope())
				{
					try
					{
						using (var conn = new SqlConnection())
						using (var adapter = new SqlDataAdapter())
						{
							conn.ConnectionString = "Data Source=.;Integrated Security=true;Initial Catalog=TestErrorWhileLockedInTrigger";

							var table = new DataTable("Table");

							table.Columns.Add("RowID", typeof(int)).AutoIncrement = true;
							table.Columns.Add("ShouldLockTable", typeof(bool));

							table.PrimaryKey = new[] { table.Columns[0] };

							table.Rows.Add(-1, shouldLockTable);

							adapter.InsertCommand =
								new SqlCommand()
								{
									CommandText = "TableToTriggerAndLock_Insert",
									CommandType = CommandType.StoredProcedure,
									UpdatedRowSource = UpdateRowSource.FirstReturnedRecord,
								};

							adapter.InsertCommand.Parameters.Add(new SqlParameter("@ShouldLockTable", SqlDbType.Bit) { SourceColumn = "ShouldLockTable" });
							adapter.InsertCommand.Connection = conn;

							conn.Open();

							try
							{
								adapter.Update(table);
							}
							catch
							{
								Console.WriteLine("Good: Error was thrown in the adapter.Update call.");
								gotExpectedError = true;

								throw;
							}

							conn.Close();

							transaction.Complete();

							transactionCompleted = true;
						}
					}
					catch
					{
						if (!gotExpectedError)
							Console.WriteLine("Indeterminate: Unexpected error was thrown.");

						throw;
					}
				}
			}
			catch
			{
				if (transactionCompleted)
				{
					Console.WriteLine("BAD: Error was not detected, C# code still thought the transaction was active,");
					Console.WriteLine("     exception was only thrown when it tried to COMMIT TRANSACTION.");
				}
				else
					Console.WriteLine("(secondary exception thrown during TransactionScope.Dispose())");
			}
		}
	}
}
