using Microsoft.VisualBasic.FileIO;
using RINGS.Controllers;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace RINGS.Common
{
    public class Completion
    {
        private static readonly Lazy<Completion> instance = new Lazy<Completion>(() => new Completion());

        public static Completion Instance => instance.Value;
        public class data
        {
            public int code { get; set; }
            public string text { get; set; }
            public data(int code, string text)
            {
                this.code = code;
                this.text = text;
            }
        }
        public List<data> completion_List = new List<data>();
        public Completion()
        {
        }
        public async Task StartAsync() => await Task.Run(() =>
        {
            TextFieldParser parser = new TextFieldParser(".\\Completion.ja.csv");
            parser.TextFieldType = FieldType.Delimited;
            parser.SetDelimiters(",");
            parser.ReadFields();
            parser.ReadFields();
            parser.ReadFields();
            while (parser.EndOfData == false)
            {
                string[] col = parser.ReadFields();
                var code = 0;
                var text = "";

                for (int i = 0; i < col.Length; i++)
                {
                    if (i == 0)
                    {
                        code = Int32.Parse(col[i]);
                    }
                    if (i == 4)
                    {
                        text = col[i];
                    }
                }
                var cls = new data(code, text);
                completion_List.Add(cls);
            }
            Debug.WriteLine(completion_List.Count);
        });
    }

}
