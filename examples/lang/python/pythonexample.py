
import json


for counter in range(1, @nrcount):  # Loop from 1 to 10
	print(f"done_{counter}")
 

# Define a simple Python structure (e.g., a dictionary)
example_struct = {
    "name": "John Doe",
    "age": @nrcount,
    "is_member": True,
    "skills": ["Python", "Data Analysis", "Machine Learning"]
}

# Convert the structure to a JSON string
json_string = json.dumps(example_struct, indent=4)

# Print the JSON string
print("==RESULT==")
print(json_string)