<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.Collections" %>
<%@ page import="com.ims185.model.Item" %>
<%@ page import="com.ims185.model.User" %>
<%@ page import="com.ims185.util.Stack" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.stream.Collectors" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Inventory Management - IMS-185</title>
    <style>
        *, *::before, *::after {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }


        body {
            font-family: 'Roboto', sans-serif;
            background-color: #f0f0f0;
            color: #333;
            line-height: 1.6;
        }

        .container {
            display: flex;
            min-height: 100vh;
        }

        .sidebar {
            width: 250px;
            background-color: #222;
            color: #fff;
            padding: 20px;
        }

        .main-content {
            flex: 1;
            padding: 20px;
        }

        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 0;
            margin-bottom: 20px;
        }

        .header-left {
            font-size: 1.5em;
            font-weight: bold;
            color: #e50914;
        }

        .header-right {
            text-align: right;
            color: #000000;
        }

        .sidebar h1 {
            font-size: 1.5em;
            margin-bottom: 20px;
            color: #e50914;
        }

        .sidebar ul {
            list-style: none;
            padding: 0;
        }

        .sidebar li {
            margin-bottom: 10px;
        }

        .sidebar a {
            color: #fff;
            text-decoration: none;
            display: block;
            padding: 10px;
            border-radius: 5px;
            transition: background-color 0.3s ease;
        }

        .sidebar a:hover {
            background-color: #444;
        }

        .sidebar a.active {
            background-color: #e50914;
            font-weight: bold;
        }

        .section {
            background-color: #fff;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }

        .section h2, .section h3 {
            margin-bottom: 15px;
            color: #555;
            border-bottom: 1px solid #eee;
            padding-bottom: 5px;
        }

        .form-group {
            margin-bottom: 15px;
        }

        .form-group label {
            display: block;
            margin-bottom: 5px;
            color: #777;
        }

        .form-group input {
            width: 100%;
            padding: 10px;
            border: 1px solid #ccc;
            border-radius: 5px;
            font-size: 1em;
            background-color: #f9f9f9;
        }

        .submit-button {
            background-color: #e50914;
            color: #fff;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            transition: background-color 0.3s ease;
        }

        .submit-button:hover {
            background-color: #c40812;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }

        th, td {
            padding: 10px;
            text-align: left;
            border: 1px solid #eee;
        }

        th {
            background-color: #f5f5f5;
            color: #333;
        }

        .action-links a {
            color: #e50914;
            text-decoration: none;
            margin-right: 10px;
        }

        .action-links a:hover {
            text-decoration: underline;
        }

        img {
            max-width: 100%;
            height: auto;
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        .fade-in {
            animation: fadeIn 0.5s ease-in-out;
        }        @media (max-width: 768px) {
            .container {
                flex-direction: column;
            }

            .sidebar {
                width: 100%;
            }

            .form-group input {
                width: 100%;
            }
        }

        /* Styles for newly added or updated items */
        .new-item {
            background-color: #ffeeee;
            transition: background-color 1s ease;
            animation: highlight-pulse 2s ease-in-out infinite;
        }

        .recent-item {
            padding: 10px;
            margin-bottom: 5px;
            border-left: 3px solid #e50914;
            background-color: #f9f9f9;
        }

        .highlight-text {
            color: #e50914;
            font-weight: bold;
        }

        @keyframes highlight {
            0% { background-color: #ffe8e8; }
            100% { background-color: transparent; }
        }

        @keyframes highlight-pulse {
            0% { background-color: #ffeeee; }
            50% { background-color: #fff5f5; }
            100% { background-color: #ffeeee; }
        }
    </style>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            const navLinks = document.querySelectorAll(".sidebar a");
            const currentPath = window.location.pathname.split("/").pop();
            navLinks.forEach(link => {
                const linkPath = link.getAttribute("href");
                if (linkPath === currentPath) {
                    link.classList.add("active");
                }
            });
        });
    </script>
</head>
<body>
<%
    User user = (User) session.getAttribute("loggedInUser");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    Stack<Item> itemStack = (Stack<Item>) session.getAttribute("itemStack");
    if (itemStack == null) {
        itemStack = new Stack<>();
        session.setAttribute("itemStack", itemStack);
    }    List<Item> items = (List<Item>) request.getAttribute("items");
    String searchQuery = request.getParameter("search");
    if (searchQuery != null && !searchQuery.isEmpty()) {
        items = items.stream()
                .filter(item -> item.getItemId().contains(searchQuery) || item.getName().contains(searchQuery))
                .collect(Collectors.toList());
    }

    // Check for newly added or updated items
    String newItemId = (String) request.getAttribute("newItemId");
    String updatedItemId = (String) request.getAttribute("updatedItemId");
    String deletedItemId = (String) request.getAttribute("deletedItemId");

    if (items != null && !items.isEmpty()) {
        // If we have a newly added or updated item, move it to the top of the stack
        if (newItemId != null || updatedItemId != null) {
            String targetId = newItemId != null ? newItemId : updatedItemId;

            // Find the item in our list
            Item targetItem = null;
            for (Item item : items) {
                if (item.getItemId().equals(targetId)) {
                    targetItem = item;
                    break;
                }
            }

            if (targetItem != null) {
                // Use the moveToTop method to move the item to the top of the stack
                itemStack.moveToTop(targetItem);
            }
        }
    }

    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
    SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm:ss");
%>
<div class="container">
    <div class="sidebar">
        <h1>Navigation</h1>
        <ul>
            <li><a href="<%= request.getContextPath() %>/dashboard" <%= request.getRequestURI().contains("dashboard") ? "class=\"active\"" : "" %>>Dashboard</a></li>
            <% if (user.getRole().equals("admin")) { %>
            <li><a href="<%= request.getContextPath() %>/user_management" <%= request.getRequestURI().contains("user_management") ? "class=\"active\"" : "" %>>Manage Users</a></li>
            <% } %>
            <li><a href="<%= request.getContextPath() %>/inventory" <%= request.getRequestURI().contains("inventory") ? "class=\"active\"" : "" %>>Manage Inventory</a></li>
            <li><a href="<%= request.getContextPath() %>/customer_management" <%= request.getRequestURI().contains("customer_management") ? "class=\"active\"" : "" %>>Manage Customers</a></li>
            <li><a href="<%= request.getContextPath() %>/update_profile" <%= request.getRequestURI().contains("update_profile") ? "class=\"active\"" : "" %>>Update Profile</a></li>
            <li><a href="<%= request.getContextPath() %>/items" <%= request.getRequestURI().contains("items") ? "class=\"active\"" : "" %>>View Items</a></li>
            <li><a href="<%= request.getContextPath() %>/reports" <%= request.getRequestURI().contains("reports") ? "class=\"active\"" : "" %>>Reports Dashboard</a></li>
            <li><a href="<%= request.getContextPath() %>/analytics" <%= request.getRequestURI().contains("analytics") ? "class=\"active\"" : "" %>>Analytics Overview</a></li>
            <li><a href="<%= request.getContextPath() %>/suppliers" <%= request.getRequestURI().contains("suppliers") ? "class=\"active\"" : "" %>>Supplier Management</a></li>
            <li><a href="<%= request.getContextPath() %>/orders" <%= request.getRequestURI().contains("orders") ? "class=\"active\"" : "" %>>Order Processing</a></li>
            <li><a href="<%= request.getContextPath() %>/returns" <%= request.getRequestURI().contains("returns") ? "class=\"active\"" : "" %>>Returns Management</a></li>
            <li><a href="<%= request.getContextPath() %>/stockalerts" <%= request.getRequestURI().contains("stockalerts") ? "class=\"active\"" : "" %>>Stock Alerts</a></li>
            <li><a href="<%= request.getContextPath() %>/activitylog" <%= request.getRequestURI().contains("activitylog") ? "class=\"active\"" : "" %>>User Activity Log</a></li>
            <li><a href="<%= request.getContextPath() %>/settings" <%= request.getRequestURI().contains("settings") ? "class=\"active\"" : "" %>>Settings Configuration</a></li>
            <li><a href="<%= request.getContextPath() %>/audittrail" <%= request.getRequestURI().contains("audittrail") ? "class=\"active\"" : "" %>>Audit Trail</a></li>
            <li><a href="<%= request.getContextPath() %>/notice_board" <%= request.getRequestURI().contains("notice_board") ? "class=\"active\"" : "" %>>Notice Board</a></li>
            <li><a href="<%= request.getContextPath() %>/logout">Logout</a></li>
        </ul>
    </div>
    <div class="main-content">
        <div class="header">
            <div class="header-left">IMS-185</div>
            <div class="header-right">User: <%= user.getUsername() %> (Role: <%= user.getRole() %>)</div>
        </div>        <section class="section">
        <h2>Inventory Management</h2>

        <% if (newItemId != null) { %>
        <div class="fade-in" style="background-color: #e5f9e5; padding: 12px; border-left: 4px solid #28a745; margin-bottom: 15px;">
            <p><strong>Success!</strong> New item has been added successfully and appears at the top of the list.</p>
        </div>
        <% } else if (updatedItemId != null) { %>
        <div class="fade-in" style="background-color: #e5f9e5; padding: 12px; border-left: 4px solid #28a745; margin-bottom: 15px;">
            <p><strong>Success!</strong> Item has been updated successfully and appears at the top of the list.</p>
        </div>
        <% } else if (deletedItemId != null) { %>
        <div class="fade-in" style="background-color: #ffe8e8; padding: 12px; border-left: 4px solid #dc3545; margin-bottom: 15px;">
            <p><strong>Success!</strong> Item with ID <%= deletedItemId %> has been deleted successfully.</p>
        </div>
        <% } %>

        <!-- Recently Modified Items Section -->
        <% if (!itemStack.isEmpty()) { %>
        <div class="section fade-in" style="margin-bottom: 15px; border-left: 4px solid #e50914;">
            <h3 style="color: #e50914;">Recently Added/Updated Items</h3>
            <div style="max-height: 150px; overflow-y: auto;">
                <%
                    // Get all items from stack without modifying it
                    List<Item> allStackItems = itemStack.getAll();

                    // Show only the 5 most recently added/modified items (which are at the end of the list)
                    int startIndex = Math.max(0, allStackItems.size() - 5);
                    List<Item> recentItems = allStackItems.subList(startIndex, allStackItems.size());

                    // Reverse the list to display most recent first
                    for (int i = recentItems.size() - 1; i >= 0; i--) {
                        Item recentItem = recentItems.get(i);
                %>
                <div class="recent-item" style="border-left: 3px solid #e50914; margin-bottom: 5px;">
                    <strong><%= recentItem.getName() %></strong>
                    <span class="highlight-text">(ID: <%= recentItem.getItemId() %>)</span> -
                    Category: <%= recentItem.getCategory() != null ? recentItem.getCategory() : "N/A" %>,
                    Stock: <%= recentItem.getStock() %>,
                    Price: $<%= String.format("%.2f", recentItem.getPrice()) %>
                    <% if (recentItem.getExpiryDate() != null && !recentItem.getExpiryDate().isEmpty()) { %>
                    , Expires: <%= recentItem.getExpiryDate() %>
                    <% } %>
                    <div style="font-size: 0.85em; color: #777; margin-top: 3px;">
                        Added: <%= recentItem.getAddedDate() != null ? recentItem.getAddedDate() : dateFormat.format(new Date()) %>,
                        Last Updated: <%= recentItem.getLastUpdatedDate() != null ? recentItem.getLastUpdatedDate() : dateFormat.format(new Date()) %>
                    </div>
                </div>
                <% } %>
            </div>
        </div>
        <% } %>

        <!-- Search and Sort -->
        <form action="<%= request.getContextPath() %>/inventory" method="get" class="fade-in">
            <div class="form-group">
                <label for="search">Search by Item ID or Name:</label>
                <input type="text" id="search" name="search" value="<%= searchQuery != null ? searchQuery : "" %>">
            </div>
            <div class="form-group">
                <label for="sort">Sort by:</label>                    <select id="sort" name="sort">
                <option value="">Select Sorting</option>
                <option value="recent" <%= "recent".equals(request.getParameter("sort")) ? "selected" : "" %>>Recently Modified</option>
                <option value="expiry" <%= "expiry".equals(request.getParameter("sort")) ? "selected" : "" %>>Expiry Date</option>
            </select>
            </div>
            <button type="submit" class="submit-button">Search/Sort</button>
        </form>

        <%
            if (items != null && !items.isEmpty()) {
        %>
        <table class="fade-in">
            <thead>
            <tr>
                <th>Name</th>
                <th>Category</th>
                <th>Stock</th>
                <th>Price</th>
                <th>Item ID</th>
                <th>Expiry Date</th>
                <th>Added Date</th>
                <th>Last Updated</th>
                <th>Image</th>
                <th>Actions</th>
            </tr>
            </thead>
            <tbody>                <%
                // Determine which items to display based on sort preference
                List<Item> displayItems = new ArrayList<>();

                // Make sure all items are in stack
                for (Item item : items) {
                    if (!itemStack.contains(item)) {
                        itemStack.push(item);
                    }
                }

                // Get all items from stack without modifying it
                List<Item> allStackItems = itemStack.getAll();

                if ("expiry".equals(request.getParameter("sort"))) {
                    // Sort by expiry date
                    displayItems = new ArrayList<>(items);
                    displayItems.sort((a, b) -> {
                        String dateA = a.getExpiryDate() != null ? a.getExpiryDate() : "9999-12-31";
                        String dateB = b.getExpiryDate() != null ? b.getExpiryDate() : "9999-12-31";
                        return dateA.compareTo(dateB);
                    });
                } else {
                    // Default order - show most recently modified first (stack order)
                    displayItems = new ArrayList<>(allStackItems);
                    // Reverse to show newest at top
                    Collections.reverse(displayItems);
                }

                for (Item item : displayItems) {
            %>                <tr<%= (newItemId != null && item.getItemId().equals(newItemId)) || (updatedItemId != null && item.getItemId().equals(updatedItemId)) ? " class=\"new-item\"" : "" %>>
                <td>
                    <%= item.getName() %>
                    <% if ((newItemId != null && item.getItemId().equals(newItemId)) || (updatedItemId != null && item.getItemId().equals(updatedItemId))) { %>
                    <span class="highlight-text"> (New/Updated)</span>
                    <% } %>
                </td>
                <td><%= item.getCategory() != null ? item.getCategory() : "N/A" %></td>
                <td><%= item.getStock() %></td>
                <td><%= String.format("%.2f", item.getPrice()) %></td>
                <td><%= item.getItemId() %></td>
                <td><%= item.getExpiryDate() != null ? item.getExpiryDate() : "N/A" %></td>
                <td><%= item.getAddedDate() != null ? item.getAddedDate() : dateFormat.format(new Date()) %></td>
                <td><%= item.getLastUpdatedDate() != null ? item.getLastUpdatedDate() : dateFormat.format(new Date()) %></td>
                <td><img src="<%= request.getContextPath() + "/" + item.getImagePath() %>" alt="Item Image" width="50"></td>
                <td>                        <form action="<%= request.getContextPath() %>/inventory" method="post" enctype="multipart/form-data" class="fade-in">
                    <input type="hidden" name="id" value="<%= item.getId() %>"/>
                    <input type="submit" name="action" value="Delete" class="submit-button">
                </form>
                    <form action="<%= request.getContextPath() %>/inventory" method="post" enctype="multipart/form-data" class="fade-in">
                        <input type="hidden" name="id" value="<%= item.getId() %>"/>
                        <div class="form-group">
                            <label for="name_<%= item.getId() %>">Name:</label>
                            <input type="text" id="name_<%= item.getId() %>" name="name" value="<%= item.getName() %>">
                        </div>
                        <div class="form-group">
                            <label for="category_<%= item.getId() %>">Category:</label>
                            <input type="text" id="category_<%= item.getId() %>" name="category" value="<%= item.getCategory() != null ? item.getCategory() : "" %>">
                        </div>
                        <div class="form-group">
                            <label for="stock_<%= item.getId() %>">Stock:</label>
                            <input type="number" id="stock_<%= item.getId() %>" name="stock" value="<%= item.getStock() %>">
                        </div>
                        <div class="form-group">
                            <label for="price_<%= item.getId() %>">Price:</label>
                            <input type="number" id="price_<%= item.getId() %>" name="price" step="0.01" value="<%= item.getPrice() %>">
                        </div>
                        <div class="form-group">                                <label for="itemId_<%= item.getId() %>">Item ID:</label>
                            <input type="text" id="itemId_<%= item.getId() %>" name="itemId" value="<%= item.getItemId() %>" title="Enter a unique item ID">
                        </div>
                        <div class="form-group">
                            <label for="expiryDate_<%= item.getId() %>">Expiry Date (yyyy-mm-dd):</label>
                            <input type="text" id="expiryDate_<%= item.getId() %>" name="expiryDate" value="<%= item.getExpiryDate() != null ? item.getExpiryDate() : "" %>">
                        </div>
                        <div class="form-group">
                            <label for="image_<%= item.getId() %>">Image:</label>
                            <input type="file" id="image_<%= item.getId() %>" name="image" accept="image/*">
                        </div>
                        <input type="submit" name="action" value="Update" class="submit-button">
                    </form>
                </td>
            </tr>
            <% } %>
            </tbody>
        </table>
        <%
        } else {
        %>
        <p>No items available.</p>
        <%
            }
        %>

        <h3>Add New Item</h3>
        <form action="<%= request.getContextPath() %>/inventory" method="post" enctype="multipart/form-data" class="fade-in">
            <div class="form-group">
                <label for="name">Name:</label>
                <input type="text" id="name" name="name" required>
            </div>
            <div class="form-group">
                <label for="category">Category:</label>
                <input type="text" id="category" name="category">
            </div>
            <div class="form-group">
                <label for="stock">Stock:</label>
                <input type="number" id="stock" name="stock" required>
            </div>
            <div class="form-group">
                <label for="price">Price:</label>
                <input type="number" id="price" name="price" step="0.01" required>
            </div>                <div class="form-group">
            <label for="itemId">Custom Item ID:</label>
            <input type="text" id="itemId" name="itemId" required placeholder="Enter your custom item ID" title="Enter a unique identifier for this item">
        </div>
            <div class="form-group">
                <label for="expiryDate">Expiry Date (yyyy-mm-dd):</label>
                <input type="text" id="expiryDate" name="expiryDate">
            </div>
            <div class="form-group">
                <label for="image">Image:</label>
                <input type="file" id="image" name="image" accept="image/*">
            </div>
            <input type="submit" name="action" value="Add" class="submit-button">
        </form>
        <a href="<%= request.getContextPath() %>/dashboard" class="action-links">Back to Dashboard</a>
    </section>
    </div>
</div>
</body>
</html>