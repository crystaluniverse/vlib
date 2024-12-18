import os

def includes_process_text(text):
    lines = text.split('\n')
    result = {}
    current_block = None
    current_content = []
    
    for line in lines:
        stripped_line = line.strip()
        if stripped_line.startswith('<') and stripped_line.endswith('>') and not stripped_line.startswith('<END'):
            if current_block:
                raise Exception(f"should not come here, there needs to be <END> after a block.\n{line}")
            #     result[current_block.upper()] = '\n'.join(current_content).rstrip()                
            current_block = stripped_line[1:-1]  # Remove '<' and '>'
            current_content = []
        elif stripped_line == '<END>':
            if current_block:
                result[current_block] = '\n'.join(current_content).rstrip()
                current_block = None
                current_content = []
        elif current_block is not None:
            current_content.append(line)
    
    if current_block:
        raise Exception(f"should not come here, there needs to be <END> after a block.\n{line}")
        result[current_block] = '\n'.join(current_content).rstrip()
    
    return result

def include_process_directory(path):
    path = os.path.expanduser(path)
    if not os.path.exists(path):
        raise FileNotFoundError(f"The path '{path}' does not exist.")    
    all_blocks = {}    
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.startswith('include_'):
                file_path = os.path.join(root, file)
                print(f" -- include {file_path}")
                with open(file_path, 'r') as f:
                    content = f.read()
                blocks = includes_process_text(content)
                all_blocks.update(blocks)
    return all_blocks

def include_process_text(input_text, block_dict):
    lines = input_text.split('\n')
    result_lines = []
    
    for line in lines:
        stripped_line = line.strip()
        if stripped_line.startswith('//include<') and stripped_line.endswith('>'):
            key = stripped_line[10:-1].upper()  # Extract and uppercase the key
            if key in block_dict:
                # Include the block exactly as it is in the dictionary
                result_lines.append(block_dict[key])
            else:
                result_lines.append(f"// ERROR: Block '{key}' not found in dictionary")
        else:
            result_lines.append(line)
    
    return '\n'.join(result_lines)

if __name__ == "__main__":
    # Example usage
    input_text = """
<BASE>
    oid string //is unique id for user in a circle, example=a7c  *
    name string //short name for swimlane'
    time_creation int //time when signature was created, in epoch  example=1711442827 *
    comments []string //list of oid's of comments linked to this story
<END>

<MYNAME>
this is my name, one line only
<END>
"""

    #parsed_blocks = include_parse_blocks(input_text)

    includes_dict = include_process_directory("~/code/git.ourworld.tf/projectmycelium/hero_server/lib/openrpclib/parser/examples")

    for key, value in includes_dict.items():
        print(f"{key}:")
        print(value)
        print()  # Add a blank line between blocks for readability
        
    input_text = '''
//we didn't do anything for comments yet
//
//this needs to go to description in openrpc spec
//
@[rootobject]
struct Story {
    //include<BASE>
    content string //description of the milestone example="this is example content which gives more color" *
    owners []string //list of users (oid) who are the owners of this project example="10a,g6,aa1" *
    notifications []string //list of users (oid) who want to be informed of changes of this milestone example="ad3"
    deadline int //epoch deadline for the milestone example="1711442827" *
    projects []string //link to a projects this story belongs too
    milestones []string //link to the mulestones this story belongs too
}
'''

    result = include_process_text(input_text, includes_dict)
    print(result)