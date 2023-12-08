//packages needed throughout the code
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

//main - runs the app
void main() {
  runApp(const MyApp());
}

// This widget is the home page of my application. It is stateful, meaning
// that it has a State object (defined below) that contains fields that affect
// how it looks.
// This class is the configuration for the state. It holds the values (in this
// case the title) provided by the parent (in this case the App widget) and
// used by the build method of the State. Fields in a Widget subclass are
// always marked "final".

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//creates the header of the page
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    //get day and format it using the provided function from the package
    DateTime now = new DateTime.now();
    String formattedDate = DateFormat('EEEE, d MMMM yyyy').format(now);

    //title
    return MaterialApp(
      title: 'DailyLou',

      //theme of the page
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      //Formatted date and puts at the top of the page
      home: MyHomePage(title: formattedDate),
    );
  }
}

//formats the home page
class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    //app bar title
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      //the body - cals MyWidget after creating a padding for visual aesthetic
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(10),
          height: MediaQuery.of(context).size.height,
          child: MyWidget(),
        ),
      ),
    );
  }
}

//main widget which calls the big widget of YourWidget
class MyWidget extends StatefulWidget {
  @override
  _YourWidgetState createState() => _YourWidgetState();
}

//class that deals with the bulk of the news
class _YourWidgetState extends State<MyWidget> {
  List<Map<String, dynamic>> articleList = [];

  //puts articles in when app is initiallly loaded
  @override
  void initState() {
    super.initState();

    // Fetch news data when the widget is created
    fetchNews();
  }

  //function to refreshNews
  Future<void> _refreshNews() async {
    // Clear current list so it resets each time that this is called
    articleList.clear();

    //waits for fetchnews to run
    await fetchNews();
  }

  //this displays the news
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //this deals with refreshing the page by scrolling up
      resizeToAvoidBottomInset: false,
      body: RefreshIndicator(
        onRefresh: _refreshNews,

        //content of the page
        child: Column(
          children: [
            //if the article is empty show the centered loading symbol
            if (articleList.isEmpty)
              Center(
                child: CircularProgressIndicator(),
              )

            //else, display the articles
            else
              Container(
                //the height of displaying the articles
                height: MediaQuery.of(context).size.height * 0.8,

                //the actual displaying of the articles in a List View form
                child: ListView.builder(
                  itemCount: articleList.length,
                  itemBuilder: (context, index) {
                    final article = articleList[index];

                    //return the ListTile so that app can see when user wants to open the url
                    return ListTile(
                      title: GestureDetector(
                        onTap: () {
                          launch(article[
                              'url']); // Uses the url from the article to launch a URL
                        },

                        //text of the title of the article with hyperlink (designs hyperlink to appear as hyperlinks usually do)
                        child: Text(
                          article['title'] ?? '',
                          style: TextStyle(
                            decoration: TextDecoration
                                .underline, // Underline the text to indicate it's clickable
                            color: Colors
                                .blue, // Set the color to blue for a typical hyperlink color
                            // fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      subtitle: Text(article['content'] ?? ''),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  //creates the list of articles to be printed
  Future<void> fetchNews() async {
    //clears current list so it resets each time that this is called
    articleList.clear();

    //api key and apiurl
    final String apiKey = '9584d63c6dac4bb39619866cc53402fc';
    final String apiUrl =
        'https://newsapi.org/v2/top-headlines?country=us&apiKey=$apiKey';

    //searches for the api
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // If there are articles, Extract and process up to 8 articles
        if (data.containsKey('articles')) {
          final List<dynamic> articles = data['articles'];

          // Shuffle the list of articles so they aren't ordered
          articles.shuffle();

          // Take the first 8 articles (randomly shuffled)
          final List<dynamic> randomArticles = articles.take(8).toList();

          //for loop going through the articles to add them to articleList
          for (var article in randomArticles) {
            final String title = article['title'];
            final String source = article['source']['name'];
            final String url = article['url'];

            //only add article to the list if there is content
            if (title != "[Removed]" &&
                source != "[Removed]" &&
                url != "[Removed]") {
              articleList.add(article);
            }
          }

          //sets state so the app knows to update
          setState(() {});
        }
        //else print error
        else {
          print('No articles key in the response.');
        }
      }

      //else print error
      else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    }
    //this catches the error if the try did not work
    catch (e) {
      print('An error occurred: $e');
    }
  }
}
