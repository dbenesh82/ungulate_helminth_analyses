tree_checking <- function(tree, data){ # enter tree and associated data, output new pdf of tree to check tree manip

  tre_dat <- filter(data, in_tree) # reduce to just that in tree
  
  # which OTL names not in tree
  uniq_otl_names <- unique(tre_dat$otl_name_red)

  for(otl in uniq_otl_names){
    # if otl just
    dx <- filter(tre_dat, otl_name_red == otl)
    if(dim(dx)[1] > 1) {
      # if more than one entry for otl name, just take first
      dx <- dx[1,]
    }
    
    if(exists('tre_dat_red')) {
      tre_dat_red <- rbind(tre_dat_red, dx)
    } else {
      tre_dat_red <- dx
    }
  }
  rm(otl, dx)
  
  # put data in same order as tree tip labels
  mv <- match(tree$tip.label, tre_dat_red$otl_name_red)
  tre_dat_red <- tre_dat_red[mv,]
  rm(mv)
  
  # map onto tree for plotting
  states_int <- map_to_state_space(tre_dat_red$ung_inf) # for the castor functions, trait has to be integer (faster)
  ac1 <- asr_max_parsimony(tree, states_int$mapped_states, Nstates = 2)
  
  mypalette <- brewer.pal(n = states_int$Nstates, "Set1")[1:2] # palette for two states
  
  tree_df <- fortify(tree) # make a df
  
  # ancestral state reconstructions to add to tree
  # if states given same probability take 1st one (not ungulate parasite)
  node_states <- apply(ac1$ancestral_likelihoods, 1, function(x) which(x == max(x))[1])
  node_states <- unlist(node_states)
  
  # combine tip and branch states, add them to tree df (correct order)
  state <- c(states_int$mapped_states, node_states)
  tree_df$state <- state
  tree_df <- mutate(tree_df, 
                    state = if_else(state == 1, "not ungulate parasite", "ungulate parasite"))
  
  # reduce to just tree structure and states
  trans_states <- select(tree_df, child_node = node, parent_node = parent, child_state = state)
  # self join to get states for both parent and child side by side
  trans_states <- left_join(trans_states, 
                            select(trans_states, child_node, parent_state = child_state),
                            by = c("parent_node" = "child_node") ) 
  # only cases where parent and child have different states
  trans_states <- filter(trans_states, child_state != parent_state)%>%
    filter(child_state == "ungulate parasite")
  #filter(tree_df, node %in% trans_statesx$child_node) # check if transitions correctly identified - looks good
  
  # add transitions to plotting df
  tree_df <- mutate(tree_df, trans_node = if_else(node %in% trans_states$parent_node, TRUE, FALSE))
  fix_labels <- substr(tree_df$label, start = 1, stop = regexpr(tree_df$label, pattern = "_") - 1 )
  tree_df$label[which(fix_labels != "")] <- fix_labels[which(fix_labels != "")]
  
  # plot tree
  p <- ggtree(tree_df) + 
    geom_tree(aes(color = state)) + 
    geom_tiplab(aes(color = state), size = 0.6) +
    geom_text2(aes(subset=!isTip, label=label), size = 2, hjust = -.025) +
    #xlim(0, max(tree_df$x)9) +
    theme(legend.position = c(0.5, 1), 
          legend.justification = c(1,1),
          legend.title = element_blank(),
          legend.text = element_text(size = 14))
  
  # add points onto plot
  #p <- p +
  # geom_nodepoint(data = filter(tree_df, trans_node), 
  #               shape = 19, size = 3, color = mypalette[2], alpha = 0.75)
  return(p)
  
}

