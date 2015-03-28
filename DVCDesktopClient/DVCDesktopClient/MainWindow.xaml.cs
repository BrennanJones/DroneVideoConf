using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

using SocketIOClient;
using SocketIOClient.Messages;


namespace DVCDesktopClient
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        #region Definitions

        private Client socket;

        private Window loginWindow;
        private Login loginForm = new Login();
        private string address;

        #endregion


        #region Constructors and Initialization

        public MainWindow()
        {
            InitializeComponent();
            InitializeConnection();
        }

        private void InitializeConnection()
        {
            loginWindow = new Window
            {
                Title = "Login",
                Content = loginForm,
                //WindowStyle = WindowStyle.None,
                Height = 165,
                Width = 310
            };

            loginForm._loginButton.Click += new RoutedEventHandler(OnLoginButtonClick);
            loginForm._server.KeyDown += new KeyEventHandler(OnLoginFormKeyDown);
            loginWindow.Closed += new EventHandler(OnLoginWindowClose);
            loginWindow.ResizeMode = System.Windows.ResizeMode.NoResize;

            loginWindow.ShowDialog();

            this.socket = new Client(this.address);
            this.socket.Message += OnMessageReceived;
            this.socket.Error += new EventHandler<ErrorEventArgs>(ConnectError);
            this.socket.On("connect", (fn) =>
            {
                // do stuff here...
            });
            this.socket.Connect();
        }

        private void ConnectError(object sender, EventArgs e)
        {
            // Through the GUI thread, close the window
            this.Dispatcher.Invoke(
                new Action(
                    delegate()
                    {
                        MessageBox.Show("Failed to connect to the server at " + this.address + ".");
                        this.Close();
                    }
            ));
        }

        #endregion


        #region Login Handlers

        private void OnLoginButtonClick(object sender, RoutedEventArgs e)
        {
            loginWindow.Close();
        }

        void OnLoginFormKeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Return)
                loginWindow.Close();
        }

        private void OnLoginWindowClose(object sender, EventArgs e)
        {
            this.address = loginForm._server.Text;
        }

        #endregion


        #region OnMessageReceived

        // Handles the event that a message is received
        private void OnMessageReceived(object sender, MessageEventArgs e)
        {
            IMessage msg = e.Message;

            if (msg != null)
            {
                // Check message name...
                switch (msg.Event)
                {
                    #region DroneVideoFrame
                    case "DroneVideoFrame":
                        // do stuff here

                        break;
                    #endregion
                }
            }
        }

        #endregion


        #region Other Handlers

        private void Window_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == System.Windows.Input.Key.Escape)
            {
                Application.Current.Shutdown(0);
            }
        }

        #endregion
    }
}
